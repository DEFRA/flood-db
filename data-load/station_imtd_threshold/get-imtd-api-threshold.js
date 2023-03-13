const axios = require('axios')

// Connect to database and generate list of station ids

const { Pool } = require('pg')

const connectionString = process.env.FLOOD_SERVICE_CONNECTION_STRING

const getDBStuff = async () => {
  const pool = new Pool({ connectionString })
  const result = await pool.query('select distinct rloi_id from rivers_mview where rloi_id is not null order by rloi_id asc')
  console.log('Number of stations from database: ', result.rows.length)
  await pool.end()
  return result.rows
}

// End database stuff

// Create csv header

const fs = require('fs')

console.log('Writing CSV header')
const csvHeader = 'station_id,fwis_code,fwis_type,direction,value\n'
fs.writeFile('./station-threshold.csv', csvHeader, err => {
  if (err) {
    console.log(err)
  }
})

const getData = (stationId) => {
  return new Promise((resolve, reject) => {
    axios
      .get(`https://imfs-prd1-thresholds-api.azurewebsites.net/Location/${stationId}?version=2`)
      .then(res => {
        try {
          res.data[0].TimeSeriesMetaData.forEach(element => {
            element.Thresholds.forEach(threshold => {
              if (element.Parameter !== 'Flow') {
                if (threshold.ThresholdType === 'FW ACT FW' ||
                            threshold.ThresholdType === 'FW ACTCON FW' ||
                            threshold.ThresholdType === 'FW RES FW' ||
                            threshold.ThresholdType === 'FW ACT FAL' ||
                            threshold.ThresholdType === 'FW ACTCON FAL' ||
                            threshold.ThresholdType === 'FW RES FAL'
                ) {
                  const direction = element.qualifier === 'Downstream Stage' ? 'd' : 'u'
                  const csvString = `${stationId},${threshold.FloodWarningArea},${threshold.FloodWarningArea[4]},${direction},${threshold.Level}\n`
                  fs.appendFile('station-threshold.csv', csvString, (err) => {
                    if (err) {
                      console.log('Append file error: ', err)
                    } else {
                      // Insert extra logging here if required.
                    }
                  })
                }
              }
            })
          })
        } catch (err) {
          console.log(`Error processing station ${stationId} - ${err}`)
        }
        return `Successfully processed station ${stationId}`
      })
      .then((data) => {
        // Insert extra logging here if required.
        resolve(data)
      })
      .catch((err) => {
        console.log(`Station ${stationId} error - ${err}`)
        resolve(`Error processing station ${stationId}. Status is ${err.response.status}`)
      })
  })
}

const main = async () => {
  const stations = await getDBStuff()
  console.log('Number of stations: ', stations.length)
  stations.map((station) => console.log('Station: ', station.rloi_id))

  const stationBuffer = []
  let stationIndex = 0

  while (stationIndex < stations.length) {
    // Limit number of concurrent calls to the IMTD api to 50

    for (let j = 0; j < 50; j++) {
      if (stationIndex < stations.length) {
        stationBuffer.push((getData(stations[stationIndex].rloi_id)))
        stationIndex++
      } else {
        break
      }
    }

    await Promise.all(stationBuffer).then(stationData => {
      console.log('stationData: ', stationData)
    })

    stationBuffer.splice(0, stationBuffer.length)

    console.log('stationIndex: ', stationIndex)
  }
}

main()

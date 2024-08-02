import Head from 'next/head'
import { generateFakeApartment } from '@/utils/fakeData'
import { Category, Collection } from '@/components'
import { getMyApartments } from '@/services/blockchain'

export default function Home({ apartmentsData }) {
  //console.log(apartmentsData)

  return (
    <div>
      <Head>
        <title>Home Page</title>
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <Category />
      <Collection apartments={apartmentsData} />
    </div>
  )
}

export const getServerSideProps = async () => {
  const apartmentsData = await getMyApartments()

  return {
    props: {
      apartmentsData: JSON.parse(JSON.stringify(apartmentsData)),
    },
  }
}

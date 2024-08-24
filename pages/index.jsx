import Head from 'next/head'
import { Category, Collection } from '@/components'
import { getMyApartments } from '@/services/blockchain'

export default function Home({ apartmentsData }) {
  return (
    <div>
      <Head>
        <title>Home Page</title>
        <link
          rel="shortcut icon"
          sizes="76x76"
          type="image/x-icon"
          href="https://a0.muscache.com/airbnb/static/logotype_favicon-21cc8e6c6a2cca43f061d2dcabdf6e58.ico"
        />
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

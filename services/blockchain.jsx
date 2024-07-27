import { ethers } from 'ethers'
import address from '@/contract/contractAddress.json'
import abi from '@/artifacts/contracts/DappBanX.json'

//include utility functions
const toWei = (num) => ethers.parseEther(num.toString())
const fromWei = (num) => ethers.fromWei(num)

//declaring variables

let ethereum, tx

if (typeof window !== 'undefined') ethereum = window.ethereum

const getEthereumContracts = async () => {
  //getting the connected wallet account
  const accounts = await ethereum?.request?.({ method: 'eth_accounts' })

  if (accounts?.length > 0) {
    //connection using browser based provider
    const provider = new ethers.BrowserProvider(ethereum)
    //signer:currently connected wallet account
    const signer = await provider.getSigner()
    //we need to pass the SC address name, the abi(deployed version of sc) and the provider signer to create an instance of the smart contract
    const contract = new ethers.Contract(address.dappBanXContract, abi.abi, signer)
    return contract
  } else {
    //connection using Json rpc provider
    const provider = new ethers.JsonRpcProvider(process.env.NEXT_PUBLIC_RPC_URL)
    const wallet = ethers.Wallet.createRandom()
    const signer = wallet.connect(provider)
    const contract = new ethers.Contract(address.dappBanXContract, abi.abi, signer)
    return contract
  }
}

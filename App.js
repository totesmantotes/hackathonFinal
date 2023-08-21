import React, { useEffect } from 'react';
import { useDispatch } from 'react-redux';
import config from '../config.json';

import { 
  loadProvider,
  loadNetwork,
  loadAccount,
  loadTokens,
  loadExchange
} from '../store/interactions';

import Navbar from './Navbar'

function App() {
  const dispatch = useDispatch();

  const loadBlockchainData = async () => {
    

    // Connect Ethers to blockchain
    const provider = loadProvider(dispatch)




    //fetch the current network's chainid like hardhat 31337, kovan is 42
    const chainId = await loadNetwork(provider, dispatch)

    
  // Reload page when network changes
    window.ethereum.on('chainChanged', () => {
      window.location.reload()
    })

    // Fetch current account & balance from Metamask when changed
    window.ethereum.on('accountsChanged', () => {
      loadAccount(provider, dispatch)
    })


    


    //had to make a vriable for the data to be callled

    //load token smart contracts
    const soshal = config[chainId].soshal
    const mETH = config[chainId].mETH
    await loadTokens(provider,[soshal.address,mETH.address], dispatch)

    //load exchange contract
    const exchangeConfig = config[chainId].exchange

    const exchange = await loadExchange(provider,exchangeConfig.address, dispatch)
    console.log(exchange.address)

  }

  useEffect(() => {
    loadBlockchainData()
  })


  return (
    <div>
      < Navbar />
      <main className='exchange grid'>
        <section className='exchange__section--left grid'>
          {/* Markets */}
          {/* Balance */}
          {/* Order */}
        </section>
        <section className='exchange__section--right grid'>
          {/* PriceChart */}
          {/* Transactions */}
          {/* Trades */}
          {/* OrderBook */}
        </section>
      </main>

      {/* Alert */}
    </div>
  );
}

export default App;

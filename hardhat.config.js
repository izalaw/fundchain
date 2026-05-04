import "dotenv/config";
import "@nomicfoundation/hardhat-toolbox";

const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
 export default {
    solidity: {
   version: "0.8.26",
         settings: {
       evmVersion: "cancun",
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    networks: {
        sepolia: {
            url: 
`https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
        },
    },
};

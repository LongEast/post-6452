#!/usr/bin/env ts-node
/* ---------------------------------------------
   Live monitor for SensorOracle → Shipper flow
   --------------------------------------------- */

import { ethers } from "ethers";
import { config } from "dotenv";
config();                                   // loads .env


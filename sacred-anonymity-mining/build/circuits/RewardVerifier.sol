// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

library Pairing {
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return r the sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {
        uint256[4] memory input = [
            p1.X, p1.Y,
            p2.X, p2.Y
        ];
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success, "pairing-add-failed");
    }

    /*
     * @return r the product of a point on G1 and a scalar, i.e.
     *         p == p.scalarMul(1) and p.plus(p) == p.scalarMul(2) for all
     *         points p.
     */
    function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input = [p.X, p.Y, s];
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success, "pairing-mul-failed");
    }

    /* @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {
        uint256[24] memory input = [
            a1.X, a1.Y, a2.X[0], a2.X[1], a2.Y[0], a2.Y[1],
            b1.X, b1.Y, b2.X[0], b2.X[1], b2.Y[0], b2.Y[1],
            c1.X, c1.Y, c2.X[0], c2.X[1], c2.Y[0], c2.Y[1],
            d1.X, d1.Y, d2.X[0], d2.X[1], d2.Y[0], d2.Y[1]
        ];
        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, mul(24, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success, "pairing-opcode-failed");
        return out[0] != 0;
    }
}

contract RewardVerifier {
    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    using Pairing for *;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[14] IC;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(uint256(759098475281635989527335747513955980245759687121416383896169341797773177779), uint256(4019797163818031023032641922478385937670120689054584192908327605234206427315));
        vk.beta2 = Pairing.G2Point([uint256(17908382337407284754985652842166899393725109154990542751270140161217608291794), uint256(3746391016054901756426271602196586154206012423506513594270208816842707648119)], [uint256(12256713065702505488205135195451762627939720061247145483061910141315511884918), uint256(10334569931815379514061094716613104387602494620665078324856935450094762353797)]);
        vk.gamma2 = Pairing.G2Point([uint256(15565664814574731673160340255438082745222666114864028015202970719620209515051), uint256(19087189896956076233831240793205800126134312329393230003276867321027345241005)], [uint256(11851256455869606759590761415098804514371543701719847912447239702648415837959), uint256(10607208523371609315572420319179436524924602676476769847550045034595002789342)]);
        vk.delta2 = Pairing.G2Point([uint256(3004079781371565443599327309355523290990249190911751418486140225656968464841), uint256(5387268765155578906456417119486673416791513861601367309534567982739540081104)], [uint256(15649845266237674666144402725894871895223207024767229738959772195764620402), uint256(5563990500095218345296567336806983429411702416332263863742354464245458027887)]);
        vk.IC[0] = Pairing.G1Point(uint256(16465623335525454941356342901844560806530663559833478572027895940590498527418), uint256(217876634365444356190284270843371078196381051205138176678336702130074691307));
        vk.IC[1] = Pairing.G1Point(uint256(12340233903756328577301007231022187258448253714307163116588891781669843067497), uint256(9761862284433448285707316137838685388539608805644442065657837838228719069182));
        vk.IC[2] = Pairing.G1Point(uint256(6263292609066218624899869709165700780767504331311676435625576470899313665803), uint256(1096141142054174107310333059518184339453438868959894440342697419758227669863));
        vk.IC[3] = Pairing.G1Point(uint256(399457057399046659238174528095874938900886146530742635790908295160507888327), uint256(13779796977082737102337824916073714741438700271667101529977771703426544104856));
        vk.IC[4] = Pairing.G1Point(uint256(17702928076724460332511487052271631263807427339547310695827429195052136607356), uint256(3069220492794298681801710900156522022986647118681108594217409520351502192542));
        vk.IC[5] = Pairing.G1Point(uint256(13731417658102226019293114875269197477110068503489313516425229166469428760462), uint256(13107735547099697119763893920334481404631007689539740568224224960844887690482));
        vk.IC[6] = Pairing.G1Point(uint256(18388621624530617123625719148324940277037097011287647499292104567318043622443), uint256(11902636229521044740956144255648837273916519136059465710585852426076486092532));
        vk.IC[7] = Pairing.G1Point(uint256(14639773656756700730049173735345136588317490780619270002514688153948028292911), uint256(18730438602669034605272525073132368757220368363431882944644672467593133039408));
        vk.IC[8] = Pairing.G1Point(uint256(2649258456503503892171952928683796405250205198177965111352913442129037308741), uint256(20211712501748195865464424427620671433829115452005214812433010445868471065536));
        vk.IC[9] = Pairing.G1Point(uint256(82847735110143732175104892885373537391667649999820077931515850490394241670), uint256(1921658334116557894259892513029410525649269435704499948433768011180923428202));
        vk.IC[10] = Pairing.G1Point(uint256(3638610872672150473986618259259778494579714722714458272727924827438829655496), uint256(1870999389181991287766935655948237581251001980064457925205045554097419931865));
        vk.IC[11] = Pairing.G1Point(uint256(17652812220564434169412555716264515684425376869132237036227448549203849689361), uint256(4728365826016815132270658021469481591162383331230091202379504437160802304626));
        vk.IC[12] = Pairing.G1Point(uint256(5588823731030408283914756021520947350389505920109884482400823036669807746230), uint256(5703300098312068884360871777536402351812082123755282001402703186698466044407));
        vk.IC[13] = Pairing.G1Point(uint256(11914426581059790027433447730104487190970568039051416205554975420324944009001), uint256(4199458003216188871757022306342911835456842882344777169003771069293720815116));

    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        bytes memory proof,
        uint256[13] memory input
    ) public view returns (bool) {
        uint256[8] memory p = abi.decode(proof, (uint256[8]));
        for (uint8 i = 0; i < p.length; i++) {
            // Make sure that each element in the proof is less than the prime q
            require(p[i] < PRIME_Q, "verifier-proof-element-gte-prime-q");
        }
        Pairing.G1Point memory proofA = Pairing.G1Point(p[0], p[1]);
        Pairing.G2Point memory proofB = Pairing.G2Point([p[2], p[3]], [p[4], p[5]]);
        Pairing.G1Point memory proofC = Pairing.G1Point(p[6], p[7]);

        VerifyingKey memory vk = verifyingKey();
        // Compute the linear combination vkX
        Pairing.G1Point memory vkX = vk.IC[0];
        for (uint256 i = 0; i < input.length; i++) {
            // Make sure that every input is less than the snark scalar field
            require(input[i] < SNARK_SCALAR_FIELD, "verifier-input-gte-snark-scalar-field");
            vkX = Pairing.plus(vkX, Pairing.scalarMul(vk.IC[i + 1], input[i]));
        }

        return Pairing.pairing(
            Pairing.negate(proofA),
            proofB,
            vk.alfa1,
            vk.beta2,
            vkX,
            vk.gamma2,
            proofC,
            vk.delta2
        );
    }
}


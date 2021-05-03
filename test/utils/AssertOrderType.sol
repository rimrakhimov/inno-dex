//SPDX-License-Identifier: MIT
pragma solidity >= 0.4.15 < 0.9.0;

import "../../contracts/libraries/SharedOrderStructs.sol";

library AssertOrderType {
    /*
        Event: TestEvent

        Fired when an assertion is made.

        Params:
            result (bool) - Whether or not the assertion holds.
            message (string) - A message to display if the assertion does not hold.
    */
    event TestEvent(bool indexed result, string message);

    // ************************************** int **************************************

    /*
        Function: equal(OrderType)

        Assert that two order types are equal.

        : A == B

        Params:
            A (OrderType) - The first order type.
            B (OrderType) - The second order type.
            message (string) - A message that is sent if the assertion fails.

        Returns:
            result (bool) - The result.
    */
    function equal(OrderType a, OrderType b, string memory message) internal returns (bool result) {
        result = (a == b);
        if (result)
            _report(result, message);
        else
            _report(result, _appendTagged(_tag(a, "Tested"), _tag(b, "Against"), message));
    }

    /*
        Function: notEqual(OrderType)

        Assert that two order types are not equal.

        : A != B

        Params:
            A (OrderType) - The first order type.
            B (OrderType) - The second order type.
            message (string) - A message that is sent if the assertion fails.

        Returns:
            result (bool) - The result.
    */
    function notEqual(OrderType a, OrderType b, string memory message) internal returns (bool result) {
        result = (a != b);
        if (result)
            _report(result, message);
        else
            _report(result, _appendTagged(_tag(a, "Tested"), _tag(b, "Against"), message));
    }

    /*
        Function: isSell(OrderType)

        Assert that an order type is 'OrderType.Sell'.

        Params:
            orderType (OrderType) - The order type.
            message (string) - A message that is sent if the assertion fails.

        Returns:
            result (bool) - The result.
    */
    function isSell(OrderType orderType, string memory message) internal returns (bool result) {
        result = (orderType == OrderType.Sell);
        if (result)
            _report(result, message);
        else
            _report(result, _appendTagged(_tag(orderType, "Tested"), message));
    }

    /*
        Function: isBuy(OrderType)

        Assert that an order type is 'OrderType.Buy'.

        Params:
            orderType (OrderType) - The order type.
            message (string) - A message that is sent if the assertion fails.

        Returns:
            result (bool) - The result.
    */
    function isBuy(OrderType orderType, string memory message) internal returns (bool result) {
        result = (orderType == OrderType.Buy);
        if (result)
            _report(result, message);
        else
            _report(result, _appendTagged(_tag(orderType, "Tested"), message));
    }

    /******************************** internal ********************************/

        /*
            Function: _report

            Internal function for triggering <TestEvent>.

            Params:
                result (bool) - The test result (true or false).
                message (string) - The message that is sent if the assertion fails.
        */
    function _report(bool result, string memory message) internal {
        if(result)
            emit TestEvent(true, "");
        else
            emit TestEvent(false, message);
    }

    /*
        Function: _ottoa

        Convert an OrderType to a string.

        Params:
            n (OrderType) - The order type.

        Returns:
            result (string) - The resulting string.
    */
    function _ottoa(OrderType t) internal pure returns (string memory) {
        return  t == OrderType.Sell ? "Sell" : "Buy";
    }

    /*
        Function: _tag(string)

        Add a tag to a string. The 'value' and 'tag' strings are returned on the form "tag: value".

        Params:
            value (string) - The value.
            tag (string) - The tag.

        Returns:
            result (string) - "tag: value"
    */
    function _tag(string memory value, string memory tag) internal pure returns (string memory) {

        bytes memory valueB = bytes(value);
        bytes memory tagB = bytes(tag);

        uint vl = valueB.length;
        uint tl = tagB.length;

        bytes memory newB = new bytes(vl + tl + 2);

        uint i;
        uint j;

        for (i = 0; i < tl; i++)
            newB[j++] = tagB[i];
        newB[j++] = ':';
        newB[j++] = ' ';
        for (i = 0; i < vl; i++)
            newB[j++] = valueB[i];

        return string(newB);
    }

    /*
        Function: _tag(OrderType)

        Add a tag to an OrderType.

        Params:
            value (OrderType) - The value.
            tag (string) - The tag.

        Returns:
            result (string) - "tag: _ottoa(value)"
    */
    function _tag(OrderType value, string memory tag) internal pure returns (string memory) {
        string memory otstr = _ottoa(value);
        return _tag(otstr, tag);
    }


    /*
        Function: _appendTagged(string)

        Append a tagged value to a string.

        Params:
            tagged (string) - The tagged value.
            str (string) - The string.

        Returns:
            result (string) - "str (tagged)"
    */
    function _appendTagged(string memory tagged, string memory str) internal pure returns (string memory) {

        bytes memory taggedB = bytes(tagged);
        bytes memory strB = bytes(str);

        uint sl = strB.length;
        uint tl = taggedB.length;

        bytes memory newB = new bytes(sl + tl + 3);

        uint i;
        uint j;

        for (i = 0; i < sl; i++)
            newB[j++] = strB[i];
        newB[j++] = ' ';
        newB[j++] = '(';
        for (i = 0; i < tl; i++)
            newB[j++] = taggedB[i];
        newB[j++] = ')';

        return string(newB);
    }

    /*
        Function: _appendTagged(string, string)

        Append two tagged values to a string.

        Params:
            tagged0 (string) - The first tagged value.
            tagged1 (string) - The second tagged value.
            str (string) - The string.

        Returns:
            result (string) - "str (tagged0, tagged1)"
    */
    function _appendTagged(string memory tagged0, string memory tagged1, string memory str) internal pure returns (string memory) {

        bytes memory tagged0B = bytes(tagged0);
        bytes memory tagged1B = bytes(tagged1);
        bytes memory strB = bytes(str);

        uint sl = strB.length;
        uint t0l = tagged0B.length;
        uint t1l = tagged1B.length;

        bytes memory newB = new bytes(sl + t0l + t1l + 5);

        uint i;
        uint j;

        for (i = 0; i < sl; i++)
            newB[j++] = strB[i];
        newB[j++] = ' ';
        newB[j++] = '(';
        for (i = 0; i < t0l; i++)
            newB[j++] = tagged0B[i];
        newB[j++] = ',';
        newB[j++] = ' ';
        for (i = 0; i < t1l; i++)
            newB[j++] = tagged1B[i];
        newB[j++] = ')';

        return string(newB);
    }
}
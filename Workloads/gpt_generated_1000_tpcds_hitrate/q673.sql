WITH intersect_orders AS (
    SELECT ws.ws_order_number FROM web_sales ws
    INTERSECT
    SELECT sr.sr_ticket_number FROM store_returns sr
)
SELECT
    cp.cp_department,
    ca1.ca_state,
    hd1.hd_buy_potential,
    CASE WHEN cs.cs_net_profit > (
            SELECT MAX(cs2.cs_net_profit) FROM catalog_sales cs2
        ) THEN 'High' ELSE 'Low' END AS profit_category,
    COUNT(DISTINCT i1.i_item_id) AS distinct_items,
    SUM(DISTINCT cs.cs_ext_sales_price) AS distinct_sales,
    SUM(l_ret.total_return_for_item) AS total_returns,
    COUNT(*) AS row_cnt
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i1
    ON cs.cs_item_sk = i1.i_item_sk
JOIN household_demographics hd1
    ON cs.cs_bill_hdemo_sk = hd1.hd_demo_sk
JOIN customer_address ca1
    ON cs.cs_bill_addr_sk = ca1.ca_address_sk
JOIN store_returns sr
    ON sr.sr_item_sk = i1.i_item_sk
JOIN reason r1
    ON sr.sr_reason_sk = r1.r_reason_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i1.i_item_sk
JOIN item i2
    ON ws.ws_item_sk = i2.i_item_sk
JOIN household_demographics hd2
    ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
JOIN customer_address ca2
    ON ws.ws_ship_addr_sk = ca2.ca_address_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i2.i_item_sk
   AND wr.wr_order_number = ws.ws_order_number
JOIN reason r2
    ON wr.wr_reason_sk = r2.r_reason_sk
CROSS JOIN LATERAL (
    SELECT SUM(sr3.sr_return_amt) AS total_return_for_item
    FROM store_returns sr3
    WHERE sr3.sr_item_sk = i1.i_item_sk
) AS l_ret
WHERE ws.ws_order_number IN (SELECT ws_order_number FROM intersect_orders)
GROUP BY
    cp.cp_department,
    ca1.ca_state,
    hd1.hd_buy_potential,
    CASE WHEN cs.cs_net_profit > (
            SELECT MAX(cs2.cs_net_profit) FROM catalog_sales cs2
        ) THEN 'High' ELSE 'Low' END
ORDER BY distinct_sales DESC
LIMIT 100

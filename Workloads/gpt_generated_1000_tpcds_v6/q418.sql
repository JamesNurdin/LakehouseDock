WITH sr_agg AS (
    SELECT
        sr_addr_sk,
        COUNT(*) AS return_cnt,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_net_loss) AS avg_net_loss,
        MAX(sr_reversed_charge) AS max_rev_charge
    FROM store_returns
    WHERE sr_return_amt > 100.00
      AND sr_reversed_charge < 500.00
      AND sr_store_credit BETWEEN 50.00 AND 2000.00
    GROUP BY sr_addr_sk
)
SELECT
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    sr_agg.return_cnt,
    sr_agg.total_return_amt,
    sr_agg.avg_net_loss,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_ext_discount_amt,
    (
        SELECT MAX(ws2.ws_ext_discount_amt)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = ws.ws_item_sk
    ) AS max_item_discount,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM customer_address ca2
            WHERE ca2.ca_zip = ca.ca_zip
              AND ca2.ca_address_sk <> ca.ca_address_sk
        ) THEN 'Multiple'
        ELSE 'Single'
    END AS zip_address_group
FROM sr_agg
JOIN customer_address ca ON sr_agg.sr_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE ca.ca_state = 'CA'
  AND ca.ca_gmt_offset BETWEEN -8.00 AND -7.00
  AND ca.ca_zip LIKE '9%'
  AND ws.ws_wholesale_cost > 30.00
  AND ws.ws_sales_price < 5000.00
ORDER BY sr_agg.total_return_amt DESC, ws.ws_sales_price DESC
LIMIT 100

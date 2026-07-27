WITH sr_agg AS (
        SELECT
            sr_cdemo_sk,
            sr_addr_sk,
            SUM(sr_return_amt)          AS total_return_amt,
            SUM(sr_net_loss)            AS total_net_loss,
            SUM(sr_return_quantity)     AS total_return_qty,
            COUNT(*)                    AS return_cnt
        FROM store_returns
        WHERE sr_return_quantity > 10
          AND sr_return_amt       > 1000
          AND sr_return_ship_cost < 2000
        GROUP BY sr_cdemo_sk, sr_addr_sk
    ),
    ws_agg AS (
        SELECT
            ws_bill_cdemo_sk AS cd_demo_sk,
            ws_bill_addr_sk  AS addr_sk,
            SUM(ws_ext_sales_price) AS total_sales,
            SUM(ws_net_profit)      AS total_profit,
            SUM(ws_quantity)        AS total_qty,
            COUNT(*)                AS sales_cnt
        FROM web_sales
        WHERE ws_net_paid_inc_tax > 1000
          AND ws_quantity          >= 2
          AND ws_ext_wholesale_cost < 5000
        GROUP BY ws_bill_cdemo_sk, ws_bill_addr_sk
    )
SELECT
    cd.cd_demo_sk,
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    cd.cd_credit_rating,
    sr_agg.total_return_amt,
    sr_agg.total_net_loss,
    ws_agg.total_sales,
    ws_agg.total_profit,
    CASE
        WHEN sr_agg.total_net_loss > ws_agg.total_profit THEN 'Loss > Profit'
        WHEN sr_agg.total_net_loss = ws_agg.total_profit THEN 'Equal'
        ELSE 'Profit > Loss'
    END AS loss_profit_category,
    RANK() OVER (ORDER BY (sr_agg.total_net_loss - ws_agg.total_profit) DESC) AS loss_profit_rank
FROM sr_agg
JOIN customer_demographics cd
    ON cd.cd_demo_sk = sr_agg.sr_cdemo_sk
JOIN customer_address ca
    ON ca.ca_address_sk = sr_agg.sr_addr_sk
JOIN ws_agg
    ON ws_agg.cd_demo_sk = cd.cd_demo_sk
   AND ws_agg.addr_sk   = ca.ca_address_sk
WHERE cd.cd_credit_rating = 'Good'
  AND ca.ca_state = 'CA'
  AND ca.ca_country = 'United States'
ORDER BY loss_profit_rank
LIMIT 100

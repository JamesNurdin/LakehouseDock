WITH ws_agg AS (
    SELECT
        c.c_customer_sk,
        d_ws_sold.d_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d_ws_sold
        ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY c.c_customer_sk, d_ws_sold.d_year
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    cd.cd_gender,
    hd.hd_income_band_sk,
    d_sr.d_year               AS return_year,
    sr.sr_refunded_cash,
    ws_agg.total_net_profit,
    RANK() OVER (PARTITION BY d_sr.d_year ORDER BY ws_agg.total_net_profit DESC) AS profit_rank,
    CASE WHEN sr.sr_refunded_cash > 100 THEN 'HIGH' ELSE 'LOW' END AS cash_category
FROM customer c
FULL OUTER JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
LEFT JOIN ws_agg
    ON ws_agg.c_customer_sk = c.c_customer_sk
   AND ws_agg.d_year = d_ws_sold.d_year
WHERE
    d_sr.d_year BETWEEN 2000 AND 2002
    AND sr.sr_refunded_cash IS NOT NULL
    AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_refunded_cash > 200
    )
ORDER BY profit_rank, c.c_customer_id
LIMIT 100

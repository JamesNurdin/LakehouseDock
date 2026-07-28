WITH
    sales_agg AS (
        SELECT
            ss.ss_store_sk,
            ss.ss_cdemo_sk,
            ss.ss_sold_date_sk,
            ss.ss_ext_sales_price,
            ss.ss_net_profit
        FROM store_sales ss
        WHERE ss.ss_quantity > 0
    ),
    web_agg AS (
        SELECT
            ws.ws_sold_date_sk,
            ws.ws_bill_cdemo_sk,
            ws.ws_ext_sales_price,
            ws.ws_net_profit
        FROM web_sales ws
        WHERE ws.ws_quantity > 0
    )
SELECT
    s.s_store_name,
    cc.cc_name,
    d.d_year,
    SUM(sa.ss_ext_sales_price + wa.ws_ext_sales_price) AS total_sales,
    SUM(sa.ss_net_profit + wa.ws_net_profit) AS total_profit,
    CASE
        WHEN SUM(sa.ss_net_profit + wa.ws_net_profit) > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status,
    COUNT(DISTINCT cd_ss.cd_gender) AS gender_count,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(sa.ss_net_profit + wa.ws_net_profit) DESC) AS profit_rank,
    (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) AS avg_profit_all
FROM sales_agg sa
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk                                    -- join 1
JOIN date_dim d
    ON sa.ss_sold_date_sk = d.d_date_sk                                 -- join 2
JOIN customer_demographics cd_ss
    ON sa.ss_cdemo_sk = cd_ss.cd_demo_sk                                 -- join 3
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk                     -- join 4
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk                               -- join 5
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk                       -- join 6
JOIN customer_demographics cd_refund
    ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk                    -- join 7
JOIN customer_demographics cd_returning
    ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk                -- join 8
JOIN web_agg wa
    ON wa.ws_sold_date_sk = d.d_date_sk                                   -- join 9 (via date_dim rule)
JOIN date_dim d_ws_ship
    ON wa.ws_sold_date_sk = d_ws_ship.d_date_sk                            -- join 10
JOIN customer_demographics cd_ws_bill
    ON wa.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk                         -- join 11
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_store_credit > 1000
      AND cr2.cr_returning_cdemo_sk = cd_ss.cd_demo_sk
)
GROUP BY s.s_store_name, cc.cc_name, d.d_year
ORDER BY total_profit DESC
LIMIT 100

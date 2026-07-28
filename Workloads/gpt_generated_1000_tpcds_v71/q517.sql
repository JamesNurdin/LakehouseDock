WITH sales_agg AS (
    SELECT
        cc.cc_state AS state,
        d.d_year   AS year,
        SUM(ss.ss_ext_sales_price)      AS store_sales_total,
        SUM(ws.ws_ext_sales_price)      AS web_sales_total,
        SUM(sr.sr_return_amt_inc_tax)   AS returns_total,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
        COUNT(DISTINCT ws.ws_order_number)  AS web_txn_cnt
    FROM call_center cc
    JOIN date_dim d
      ON cc.cc_closed_date_sk = d.d_date_sk                              -- allowed join
    JOIN store_sales ss
      ON ss.ss_sold_date_sk = d.d_date_sk                                 -- allowed join
    JOIN store_returns sr
      ON sr.sr_returned_date_sk = d.d_date_sk                             -- allowed join
     AND sr.sr_item_sk         = ss.ss_item_sk
     AND sr.sr_ticket_number   = ss.ss_ticket_number
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk                                 -- allowed join
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk        = cd.cd_demo_sk                            -- allowed join
     AND sr.sr_cdemo_sk        = cd.cd_demo_sk
     AND ws.ws_bill_cdemo_sk   = cd.cd_demo_sk
    WHERE d.d_year = 2002                                               -- predicate 1
      AND cc.cc_state = 'TX'                                            -- predicate 2
      AND cd.cd_gender = 'M'                                            -- predicate 3
      AND ss.ss_quantity > 1                                            -- predicate 4
      AND EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_sold_date_sk = d.d_date_sk
              AND ws2.ws_net_paid > 5000
        )
    GROUP BY GROUPING SETS (
        (cc.cc_state, d.d_year),
        (cc.cc_state),
        (d.d_year),
        ()
    )
)
SELECT
    sa.state,
    sa.year,
    sa.store_sales_total,
    sa.web_sales_total,
    sa.returns_total,
    (sa.store_sales_total + sa.web_sales_total - sa.returns_total) AS total_sales,
    avg_overall.avg_total_sales
FROM (
    SELECT
        state,
        year,
        store_sales_total,
        web_sales_total,
        returns_total
    FROM sales_agg
) sa
CROSS JOIN (
    SELECT AVG(store_sales_total + web_sales_total - returns_total) AS avg_total_sales
    FROM sales_agg
) avg_overall
WHERE (sa.store_sales_total + sa.web_sales_total - sa.returns_total) > avg_overall.avg_total_sales
ORDER BY total_sales DESC
LIMIT 100

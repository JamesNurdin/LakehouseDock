WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_hdemo_sk,
        SUM(cs.cs_net_paid)            AS total_net_paid,
        SUM(cs.cs_ext_discount_amt)    AS total_discount,
        COUNT(*)                       AS cnt_sales
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (10)               -- sample 10% of catalog_sales
    GROUP BY
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_hdemo_sk
)
SELECT
    d_cs.d_year,
    cd_bill.cd_gender,
    hd_bill.hd_buy_potential,
    SUM(cs_agg.total_net_paid)     AS sum_net_paid,
    SUM(cs_agg.total_discount)    AS sum_discount,
    COUNT(DISTINCT cs_agg.cs_order_number) AS distinct_orders,
    CASE
        WHEN SUM(cs_agg.total_net_paid) > 100000 THEN 'High'
        ELSE 'Low'
    END                           AS revenue_category,
    GROUPING(d_cs.d_year)         AS g_year,
    GROUPING(cd_bill.cd_gender)   AS g_gender,
    GROUPING(hd_bill.hd_buy_potential) AS g_potential
FROM cs_agg
JOIN date_dim d_cs
    ON cs_agg.cs_sold_date_sk = d_cs.d_date_sk
JOIN customer_demographics cd_bill
    ON cs_agg.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON cs_agg.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = cs_agg.cs_item_sk
   AND cr.cr_order_number = cs_agg.cs_order_number
LEFT JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
LEFT JOIN store_sales ss
    ON ss.ss_item_sk = cs_agg.cs_item_sk
LEFT JOIN date_dim d_ss
    ON ss.ss_sold_date_sk = d_ss.d_date_sk
LEFT JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
LEFT JOIN web_sales ws
    ON ws.ws_item_sk = cs_agg.cs_item_sk
LEFT JOIN date_dim d_ws
    ON ws.ws_sold_date_sk = d_ws.d_date_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
WHERE d_cs.d_year BETWEEN 1999 AND 2001
  AND hd_bill.hd_vehicle_count >= 0
  AND r_cr.r_reason_desc IS NOT NULL
GROUP BY ROLLUP (d_cs.d_year, cd_bill.cd_gender, hd_bill.hd_buy_potential)
ORDER BY d_cs.d_year ASC NULLS FIRST,
         cd_bill.cd_gender ASC NULLS FIRST,
         hd_bill.hd_buy_potential ASC NULLS FIRST
LIMIT 100

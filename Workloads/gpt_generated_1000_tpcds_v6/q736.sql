/*
Goal: Analyze total net loss from store and catalog returns by year/month, store and product brand, classifying high‑loss rows, applying realistic filters, and showing only groups with significant loss.
*/
WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        i.i_brand,
        sr.sr_ticket_number,
        sr.sr_net_loss,
        cr.cr_order_number,
        cr.cr_net_loss,
        r.r_reason_desc AS store_reason,
        r2.r_reason_desc AS catalog_reason,
        ca.ca_country,
        cd.cd_gender,
        cc.cc_market_manager,
        cp.cp_type
    FROM date_dim d
    INNER JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN item i
        ON i.i_item_sk = sr.sr_item_sk
    INNER JOIN reason r
        ON r.r_reason_sk = sr.sr_reason_sk
    INNER JOIN store s
        ON s.s_store_sk = sr.sr_store_sk
    INNER JOIN customer_address ca
        ON ca.ca_address_sk = sr.sr_addr_sk
    INNER JOIN customer_demographics cd
        ON cd.cd_demo_sk = sr.sr_cdemo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN call_center cc
        ON cc.cc_call_center_sk = cr.cr_call_center_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    LEFT JOIN reason r2
        ON r2.r_reason_sk = cr.cr_reason_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#21'
      AND s.s_state = 'CA'
      AND ca.ca_country = 'United States'
      AND cd.cd_gender = 'M'
      AND cp.cp_type = 'monthly'
)
SELECT
    d_year,
    d_month_seq,
    s_store_name,
    i_brand,
    SUM(COALESCE(sr_net_loss, 0) + COALESCE(cr_net_loss, 0)) AS total_net_loss,
    COUNT(DISTINCT sr_ticket_number) AS store_return_cnt,
    COUNT(DISTINCT cr_order_number) AS catalog_return_cnt,
    SUM(CASE WHEN COALESCE(sr_net_loss, 0) + COALESCE(cr_net_loss, 0) > 1000 THEN 1 ELSE 0 END) AS high_loss_rows
FROM base
GROUP BY
    d_year,
    d_month_seq,
    s_store_name,
    i_brand
HAVING SUM(COALESCE(sr_net_loss, 0) + COALESCE(cr_net_loss, 0)) > 5000
ORDER BY total_net_loss DESC
LIMIT 100

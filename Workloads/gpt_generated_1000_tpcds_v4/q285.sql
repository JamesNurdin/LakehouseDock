WITH store_agg AS (
        SELECT
            ss.ss_store_sk AS entity_id,
            'store' AS entity_type,
            ss.ss_sold_date_sk AS date_sk,
            ss.ss_promo_sk AS promo_sk,
            ss.ss_addr_sk AS addr_sk,
            SUM(ss.ss_net_paid) AS total_net_paid,
            SUM(ss.ss_net_profit) AS total_net_profit
        FROM tpcds.store_sales ss
        GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_promo_sk, ss.ss_addr_sk
    ),
    catalog_agg AS (
        SELECT
            cs.cs_catalog_page_sk AS entity_id,
            'catalog_page' AS entity_type,
            cs.cs_sold_date_sk AS date_sk,
            cs.cs_promo_sk AS promo_sk,
            cs.cs_bill_addr_sk AS addr_sk,
            SUM(cs.cs_net_paid) AS total_net_paid,
            SUM(cs.cs_net_profit) AS total_net_profit
        FROM tpcds.catalog_sales cs
        GROUP BY cs.cs_catalog_page_sk, cs.cs_sold_date_sk, cs.cs_promo_sk, cs.cs_bill_addr_sk
    ),
    web_return_agg AS (
        SELECT
            wr.wr_reason_sk AS entity_id,
            'reason' AS entity_type,
            wr.wr_returned_date_sk AS date_sk,
            NULL AS promo_sk,
            wr.wr_refunded_addr_sk AS addr_sk,
            SUM(wr.wr_return_amt) AS total_net_paid,
            -SUM(wr.wr_net_loss) AS total_net_profit
        FROM tpcds.web_returns wr
        GROUP BY wr.wr_reason_sk, wr.wr_returned_date_sk, wr.wr_refunded_addr_sk
    ),
    combined AS (
        SELECT * FROM store_agg
        UNION ALL
        SELECT * FROM catalog_agg
        UNION ALL
        SELECT * FROM web_return_agg
    )
SELECT
    d.d_date,
    COALESCE(s.s_store_name, cp.cp_description, r.r_reason_desc) AS entity_name,
    CASE
        WHEN c.entity_type = 'store' THEN 'Store Sales'
        WHEN c.entity_type = 'catalog_page' THEN 'Catalog Sales'
        ELSE 'Web Returns'
    END AS source_category,
    SUM(c.total_net_paid) AS sum_net_paid,
    SUM(c.total_net_profit) AS sum_net_profit,
    COUNT(*) AS record_cnt,
    CASE
        WHEN SUM(c.total_net_profit) > 0 THEN 'POSITIVE'
        ELSE 'NEGATIVE_OR_ZERO'
    END AS profit_indicator
FROM combined c
JOIN tpcds.date_dim d ON c.date_sk = d.d_date_sk
LEFT JOIN tpcds.store s ON c.entity_type = 'store' AND c.entity_id = s.s_store_sk
LEFT JOIN tpcds.catalog_page cp ON c.entity_type = 'catalog_page' AND c.entity_id = cp.cp_catalog_page_sk
LEFT JOIN tpcds.reason r ON c.entity_type = 'reason' AND c.entity_id = r.r_reason_sk
JOIN tpcds.customer_address ca ON c.addr_sk = ca.ca_address_sk
LEFT JOIN tpcds.promotion p ON c.promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
  AND (p.p_channel_email = 'N' OR p.p_channel_email IS NULL)
  AND ca.ca_country = 'United States'
  AND (s.s_state = 'CA' OR s.s_state IS NULL)
  AND (r.r_reason_desc LIKE '%damaged%' OR r.r_reason_desc IS NULL)
GROUP BY d.d_date,
         COALESCE(s.s_store_name, cp.cp_description, r.r_reason_desc),
         CASE
            WHEN c.entity_type = 'store' THEN 'Store Sales'
            WHEN c.entity_type = 'catalog_page' THEN 'Catalog Sales'
            ELSE 'Web Returns'
         END
HAVING SUM(c.total_net_paid) > 1000
ORDER BY d.d_date DESC, sum_net_paid DESC
LIMIT 100

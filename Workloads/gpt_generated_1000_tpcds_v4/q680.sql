WITH cs_agg AS (
    SELECT
        cs_item_sk,
        cs_order_number,
        cs_sold_date_sk,
        cs_catalog_page_sk,
        cs_promo_sk,
        cs_bill_addr_sk,
        cs_bill_cdemo_sk,
        cs_bill_hdemo_sk,
        SUM(cs_ext_sales_price)      AS total_sales,
        AVG(cs_sales_price)          AS avg_price,
        COUNT(*)                     AS sales_cnt
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2001
          AND d_month_seq = 12
    )
    GROUP BY
        cs_item_sk,
        cs_order_number,
        cs_sold_date_sk,
        cs_catalog_page_sk,
        cs_promo_sk,
        cs_bill_addr_sk,
        cs_bill_cdemo_sk,
        cs_bill_hdemo_sk
)
SELECT
    d.d_year,
    s.s_store_name,
    we.web_name,
    cp.cp_department,
    p.p_promo_name,
    SUM(cs_agg.total_sales) AS sum_total_sales,
    COUNT(DISTINCT cs_agg.cs_order_number) AS distinct_orders,
    AVG(cs_agg.avg_price)               AS avg_price,
    MIN(cs_agg.total_sales)             AS min_total_sales,
    MAX(cs_agg.total_sales)             AS max_total_sales
FROM cs_agg
JOIN date_dim d        ON cs_agg.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp   ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p       ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN customer_address ca ON cs_agg.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cs_agg.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs_agg.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs_agg.cs_order_number
                         AND cr.cr_item_sk = cs_agg.cs_item_sk
JOIN reason r_cr       ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN store_sales ss    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s           ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr  ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_returned_date_sk = d.d_date_sk
JOIN reason r_sr       ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN web_sales ws      ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site we       ON ws.ws_web_site_sk = we.web_site_sk
JOIN inventory inv     ON inv.inv_date_sk = d.d_date_sk
WHERE p.p_channel_radio = 'N'
  AND ib.ib_lower_bound >= 100000
  AND we.web_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = cs_agg.cs_promo_sk
          AND p2.p_discount_active = 'Y'
    )
GROUP BY
    d.d_year,
    s.s_store_name,
    we.web_name,
    cp.cp_department,
    p.p_promo_name
HAVING SUM(cs_agg.total_sales) > 10000
ORDER BY sum_total_sales DESC
LIMIT 100

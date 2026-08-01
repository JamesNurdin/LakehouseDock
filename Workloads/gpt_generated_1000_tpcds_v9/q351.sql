WITH store_ret_agg AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_reason_sk,
        SUM(sr.sr_return_amt) AS sum_return_amt,
        SUM(sr.sr_net_loss) AS sum_net_loss,
        COUNT(*) AS cnt_returns
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    WHERE d_sr.d_year = 2001
      AND sr.sr_fee > 30
    GROUP BY sr.sr_customer_sk, sr.sr_reason_sk
)
SELECT
    d_cs.d_year AS sale_year,
    p.p_promo_name,
    cc.cc_name,
    ws_site.web_name,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) AS total_net_profit,
    COALESCE(SUM(sra.sum_return_amt), 0) AS total_store_return_amount,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_web_return_amount,
    AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount,
    MIN(cs.cs_quantity) AS min_quantity,
    MAX(ws.ws_quantity) AS max_quantity,
    (SELECT COUNT(*) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS total_active_promotions
FROM catalog_sales cs
JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d_cs.d_date_sk
    AND ws.ws_sold_time_sk = t_cs.t_time_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN store_ret_agg sra ON sra.sr_customer_sk = c.c_customer_sk
LEFT JOIN reason r_sr ON sra.sr_reason_sk = r_sr.r_reason_sk
WHERE d_cs.d_year = 2001
  AND ca.ca_street_type = 'Lane'
  AND cs.cs_quantity > 1
GROUP BY d_cs.d_year, p.p_promo_name, cc.cc_name, ws_site.web_name
ORDER BY total_catalog_sales DESC
LIMIT 100

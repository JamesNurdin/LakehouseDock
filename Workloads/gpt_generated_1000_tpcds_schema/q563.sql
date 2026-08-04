WITH ws_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(*) AS sales_cnt,
        ARRAY[SUM(ws.ws_ext_sales_price), AVG(ws.ws_sales_price)] AS sales_metrics
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2001
          AND d.d_month_seq BETWEEN 1 AND 12
    )
    GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    ws_agg.total_sales,
    ws_agg.avg_sales_price,
    ws_agg.sales_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    r.r_reason_desc,
    cc.cc_name,
    ca.ca_city,
    cd.cd_gender,
    hd.hd_buy_potential,
    ws_site.web_name,
    CASE u.metric_idx WHEN 1 THEN 'total_sales' WHEN 2 THEN 'avg_sales_price' ELSE 'unknown' END AS metric_type,
    u.metric_value
FROM ws_agg
JOIN web_sales ws
  ON ws.ws_item_sk = ws_agg.ws_item_sk
 AND ws.ws_sold_date_sk = ws_agg.ws_sold_date_sk
JOIN date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
 AND cr.cr_item_sk = i.i_item_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer_address ca
  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
 AND wr.wr_returned_date_sk = d.d_date_sk
 AND wr.wr_item_sk = i.i_item_sk
JOIN reason r2
  ON wr.wr_reason_sk = r2.r_reason_sk
CROSS JOIN UNNEST(ws_agg.sales_metrics) WITH ORDINALITY AS u(metric_value, metric_idx)
WHERE
    cc.cc_state = 'CA'
  AND ca.ca_state = 'TX'
  AND hd.hd_buy_potential = '>10000'
  AND ws_site.web_company_name = 'pri'
  AND cc.cc_tax_percentage > (
        SELECT MAX(cc_inner.cc_tax_percentage)
        FROM call_center cc_inner
        WHERE cc_inner.cc_state = 'CA'
      )
GROUP BY
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    ws_agg.total_sales,
    ws_agg.avg_sales_price,
    ws_agg.sales_cnt,
    r.r_reason_desc,
    cc.cc_name,
    ca.ca_city,
    cd.cd_gender,
    hd.hd_buy_potential,
    ws_site.web_name,
    u.metric_idx,
    u.metric_value
ORDER BY d.d_year DESC, ws_agg.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

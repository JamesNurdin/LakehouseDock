WITH
store_sales_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        i.i_category_id,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_category_id IN (1, 2, 3)
      AND cd.cd_gender = 'F'
      AND s.s_state = 'CA'
      AND ib.ib_upper_bound > 50000
    GROUP BY s.s_store_id, d.d_year, i.i_category_id
),
catalog_sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        d_cs.d_year,
        i.i_category_id,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_quantity) AS catalog_quantity,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_cs.d_date_sk
    WHERE d_cs.d_year BETWEEN 2000 AND 2002
      AND i.i_category_id IN (1, 2, 3)
      AND cd.cd_gender = 'F'
      AND cc.cc_state = 'CA'
      AND ib.ib_lower_bound >= 20000
    GROUP BY cc.cc_call_center_id, d_cs.d_year, i.i_category_id
),
catalog_returns_agg AS (
    SELECT
        cc.cc_call_center_id,
        d_cr.d_year,
        i.i_category_id,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(cr.cr_order_number) AS return_count
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d_cr.d_year BETWEEN 2000 AND 2002
      AND i.i_category_id IN (1, 2, 3)
      AND cd.cd_gender = 'F'
      AND cc.cc_state = 'CA'
      AND ib.ib_lower_bound >= 20000
    GROUP BY cc.cc_call_center_id, d_cr.d_year, i.i_category_id
),
call_centers_with_sales AS (
    SELECT DISTINCT cc_call_center_id FROM catalog_sales_agg
),
call_centers_with_returns AS (
    SELECT DISTINCT cc_call_center_id FROM catalog_returns_agg
),
call_centers_no_returns AS (
    SELECT cc_call_center_id FROM call_centers_with_sales
    EXCEPT
    SELECT cc_call_center_id FROM call_centers_with_returns
)
SELECT
    csag.cc_call_center_id,
    csag.d_year,
    csag.i_category_id,
    csag.catalog_net_profit,
    COALESCE(crag.total_return_loss, 0) AS total_return_loss,
    ssag.store_net_profit,
    (csag.catalog_net_profit - COALESCE(crag.total_return_loss, 0)) AS net_profit_after_returns,
    (csag.catalog_net_profit - COALESCE(crag.total_return_loss, 0)) / NULLIF(ssag.store_net_profit, 0) AS profit_ratio
FROM call_centers_no_returns cnr
JOIN catalog_sales_agg csag
    ON csag.cc_call_center_id = cnr.cc_call_center_id
LEFT JOIN catalog_returns_agg crag
    ON crag.cc_call_center_id = csag.cc_call_center_id
   AND crag.d_year = csag.d_year
   AND crag.i_category_id = csag.i_category_id
LEFT JOIN store_sales_agg ssag
    ON ssag.d_year = csag.d_year
   AND ssag.i_category_id = csag.i_category_id
WHERE csag.catalog_net_profit > 1000
  AND COALESCE(crag.total_return_loss, 0) < 500
  AND ssag.store_net_profit > 500
  AND csag.catalog_quantity > 10
  AND ssag.store_quantity > 5
ORDER BY net_profit_after_returns DESC
LIMIT 100

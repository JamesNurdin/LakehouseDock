WITH
  store_agg AS (
    SELECT
      p.p_promo_id AS p_promo_id,
      dd.d_year AS d_year,
      SUM(ss.ss_net_paid) AS net_paid,
      COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE dd.d_year = 2001
      AND dd.d_weekend = 'N'
      AND p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id, dd.d_year
  ),
  web_agg AS (
    SELECT
      p.p_promo_id AS p_promo_id,
      dd.d_year AS d_year,
      SUM(ws.ws_net_paid) AS net_paid,
      COUNT(*) AS txn_count
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE dd.d_year = 2001
      AND dd.d_weekend = 'N'
      AND p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id, dd.d_year
  ),
  catalog_agg AS (
    SELECT
      p.p_promo_id AS p_promo_id,
      dd.d_year AS d_year,
      SUM(cs.cs_net_paid) AS net_paid,
      COUNT(*) AS txn_count,
      cc.cc_name AS cc_name,
      cp.cp_description AS cp_description
    FROM catalog_sales cs
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE dd.d_year = 2001
      AND cp.cp_catalog_number IN (6, 12, 14)
      AND cc.cc_gmt_offset BETWEEN -5.00 AND 5.00
      AND p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id, dd.d_year, cc.cc_name, cp.cp_description
  ),
  union_distinct AS (
    SELECT p_promo_id, d_year, net_paid, txn_count FROM store_agg
    UNION
    SELECT p_promo_id, d_year, net_paid, txn_count FROM web_agg
    UNION
    SELECT p_promo_id, d_year, net_paid, txn_count FROM catalog_agg
  ),
  returns_agg AS (
    SELECT
      p.p_promo_id AS p_promo_id,
      dd.d_year AS d_year,
      SUM(wr.wr_return_amt) AS net_paid,
      SUM(wr.wr_return_quantity) AS txn_count
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    GROUP BY p.p_promo_id, dd.d_year
  ),
  returns_promo_ids AS (
    SELECT DISTINCT p_promo_id FROM returns_agg
  ),
  union_excluding_returns AS (
    SELECT * FROM union_distinct
    EXCEPT
    SELECT p_promo_id, d_year, net_paid, txn_count FROM returns_agg
  ),
  final_agg AS (
    SELECT
      ue.p_promo_id,
      ue.d_year,
      SUM(ue.net_paid) AS total_net_paid,
      SUM(ue.txn_count) AS total_txn,
      ROW_NUMBER() OVER (ORDER BY SUM(ue.net_paid) DESC) AS rn
    FROM union_excluding_returns ue
    WHERE ue.p_promo_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM returns_promo_ids r WHERE r.p_promo_id = ue.p_promo_id
      )
    GROUP BY ue.p_promo_id, ue.d_year
  )
SELECT
  fa.p_promo_id,
  fa.d_year,
  fa.total_net_paid,
  fa.total_txn,
  fa.rn
FROM final_agg fa
WHERE fa.total_net_paid > (
  SELECT AVG(total_net_paid) FROM final_agg
)
ORDER BY fa.total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY

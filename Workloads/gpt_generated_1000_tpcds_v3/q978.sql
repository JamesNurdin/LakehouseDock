WITH
  inv_agg AS (
    SELECT inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_date_sk
  ),
  store_ret_agg AS (
    SELECT sr_returned_date_sk,
           SUM(sr_net_loss) AS total_store_return_loss
    FROM store_returns
    GROUP BY sr_returned_date_sk
  ),
  catalog_ret_agg AS (
    SELECT cr_returned_date_sk,
           SUM(cr_net_loss) AS total_catalog_return_loss
    FROM catalog_returns
    GROUP BY cr_returned_date_sk
  ),
  combined AS (
    SELECT
      ss.ss_ticket_number            AS transaction_id,
      d.d_date                       AS transaction_date,
      d.d_year                       AS transaction_year,
      c.c_customer_id                AS customer_id,
      cd.cd_gender                   AS gender,
      hd.hd_income_band_sk           AS income_band,
      s.s_store_name                 AS store_name,
      p.p_promo_name                 AS promo_name,
      ss.ss_net_profit               AS net_profit,
      CASE WHEN ss.ss_net_profit > 1000 THEN 'High'
           WHEN ss.ss_net_profit > 0    THEN 'Medium'
           ELSE 'Low' END             AS profit_category,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ss.ss_net_profit DESC) AS rank_within_year,
      'store'                        AS sales_source,
      i.total_qty_on_hand,
      sr.total_store_return_loss    AS total_return_loss,
      cc.cc_name                    AS call_center_name,
      w.web_name                    AS web_site_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN inv_agg i ON d.d_date_sk = i.inv_date_sk
    LEFT JOIN store_ret_agg sr ON d.d_date_sk = sr.sr_returned_date_sk
    LEFT JOIN call_center cc ON d.d_date_sk = cc.cc_open_date_sk
    LEFT JOIN web_site w ON d.d_date_sk = w.web_open_date_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND p.p_channel_radio = 'N'
      AND s.s_state = 'CA'
    UNION ALL
    SELECT
      cs.cs_order_number            AS transaction_id,
      d.d_date                       AS transaction_date,
      d.d_year                       AS transaction_year,
      c.c_customer_id                AS customer_id,
      cd.cd_gender                   AS gender,
      hd.hd_income_band_sk           AS income_band,
      s.s_store_name                 AS store_name,
      p.p_promo_name                 AS promo_name,
      cs.cs_net_profit               AS net_profit,
      CASE WHEN cs.cs_net_profit > 1000 THEN 'High'
           WHEN cs.cs_net_profit > 0    THEN 'Medium'
           ELSE 'Low' END             AS profit_category,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cs.cs_net_profit DESC) AS rank_within_year,
      'catalog'                      AS sales_source,
      i.total_qty_on_hand,
      cr.total_catalog_return_loss AS total_return_loss,
      cc.cc_name                    AS call_center_name,
      w.web_name                    AS web_site_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN inv_agg i ON d.d_date_sk = i.inv_date_sk
    LEFT JOIN catalog_ret_agg cr ON d.d_date_sk = cr.cr_returned_date_sk
    LEFT JOIN web_site w ON d.d_date_sk = w.web_open_date_sk
    LEFT JOIN store s ON d.d_date_sk = s.s_closed_date_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND p.p_channel_radio = 'N'
      AND cc.cc_state = 'CA'
      AND p.p_response_target > 0
  )
SELECT
  transaction_id,
  transaction_date,
  transaction_year,
  customer_id,
  gender,
  income_band,
  store_name,
  promo_name,
  net_profit,
  profit_category,
  rank_within_year,
  sales_source,
  total_qty_on_hand,
  total_return_loss,
  call_center_name,
  web_site_name
FROM combined
ORDER BY net_profit DESC
LIMIT 100

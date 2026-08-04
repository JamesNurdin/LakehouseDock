WITH
  /* Aggregate store sales */
  store_agg AS (
    SELECT
      s.s_store_id AS store_id,
      d.d_year,
      SUM(ss.ss_net_profit) AS net_profit,
      CASE WHEN SUM(ss.ss_net_profit) > 1000000 THEN 'High' ELSE 'Low' END AS profit_category,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i1 ON ss.ss_item_sk = i1.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY s.s_store_id, d.d_year, ss.ss_sold_date_sk, ss.ss_sold_time_sk
  ),

  /* Aggregate web sales */
  web_agg AS (
    SELECT
      wp.wp_web_page_id AS page_id,
      d.d_year,
      SUM(ws.ws_net_profit) AS net_profit,
      CASE WHEN SUM(ws.ws_net_profit) > 1000000 THEN 'High' ELSE 'Low' END AS profit_category,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY wp.wp_web_page_id, d.d_year, ws.ws_sold_date_sk, ws.ws_sold_time_sk
  ),

  /* Aggregate catalog sales */
  catalog_agg AS (
    SELECT
      cc.cc_call_center_id AS call_center_id,
      d.d_year,
      SUM(cs.cs_net_profit) AS net_profit,
      CASE WHEN SUM(cs.cs_net_profit) > 1000000 THEN 'High' ELSE 'Low' END AS profit_category,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i3 ON cs.cs_item_sk = i3.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY cc.cc_call_center_id, d.d_year, cs.cs_sold_date_sk, cs.cs_sold_time_sk
  ),

  /* Aggregate catalog returns */
  returns_agg AS (
    SELECT
      r.r_reason_desc AS reason_desc,
      d_ret.d_year,
      SUM(cr.cr_net_loss) AS net_loss,
      CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS loss_category,
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN item i4 ON cr.cr_item_sk = i4.i_item_sk
    GROUP BY r.r_reason_desc, d_ret.d_year, cr.cr_returned_date_sk, cr.cr_returned_time_sk
  ),

  /* Union of store and web keys (id + year) */
  union_keys AS (
    SELECT store_id AS id, d_year FROM store_agg
    UNION
    SELECT page_id AS id, d_year FROM web_agg
  ),

  /* Catalog keys (id + year) */
  catalog_keys AS (
    SELECT call_center_id AS id, d_year FROM catalog_agg
  ),

  /* Subtract catalog keys from the union of store/web keys */
  diff_keys AS (
    SELECT id, d_year FROM union_keys
    EXCEPT
    SELECT id, d_year FROM catalog_keys
  ),

  /* Full outer join the diff set with returns to keep unmatched rows */
  final_join AS (
    SELECT
      COALESCE(dk.id, r.reason_desc) AS identifier,
      COALESCE(dk.d_year, r.d_year) AS year,
      r.net_loss,
      r.loss_category
    FROM diff_keys dk
    FULL OUTER JOIN returns_agg r
      ON dk.d_year = r.d_year
  )

SELECT
  identifier,
  year,
  net_loss,
  loss_category,
  CASE WHEN net_loss > 0 THEN 'Negative' ELSE 'Non‑Negative' END AS net_status
FROM final_join
ORDER BY year DESC, identifier
OFFSET 0 LIMIT 100

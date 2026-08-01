WITH
  base AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_state,
      i.i_item_sk,
      i.i_category,
      i.i_formulation,
      i.i_current_price,
      cd.cd_gender,
      cd.cd_education_status,
      cd.cd_marital_status,
      hd.hd_buy_potential,
      p.p_discount_active,
      ss.ss_quantity,
      ss.ss_sales_price,
      ss.ss_net_profit,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      inv.inv_quantity_on_hand,
      w.w_warehouse_name,
      wp.wp_type,
      td.t_hour,
      td.t_am_pm
    FROM store_sales ss
    JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN time_dim tr
      ON sr.sr_return_time_sk = tr.t_time_sk
    LEFT JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN warehouse w
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
     AND wr.wr_returned_time_sk = td.t_time_sk
    LEFT JOIN time_dim tw
      ON wr.wr_returned_time_sk = tw.t_time_sk
    LEFT JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cd.cd_marital_status = 'M'
      AND hd.hd_buy_potential = '5001-10000'
      AND i.i_formulation LIKE '%steel%'
      AND p.p_discount_active = 'Y'
      AND s.s_state = 'CA'
  ),
  sales_agg AS (
    SELECT
      s_store_name,
      i_category,
      SUM(ss_sales_price * ss_quantity) AS sales_amount,
      SUM(ss_net_profit) AS net_profit
    FROM base
    WHERE sr_return_quantity IS NULL
    GROUP BY s_store_name, i_category
  ),
  returns_agg AS (
    SELECT
      s_store_name,
      i_category,
      -SUM(sr_return_amt) AS sales_amount,
      0.0 AS net_profit
    FROM base
    WHERE sr_return_quantity > 0
    GROUP BY s_store_name, i_category
  ),
  combined AS (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
  ),
  final AS (
    SELECT
      s_store_name,
      i_category,
      SUM(sales_amount) AS total_sales,
      SUM(net_profit) AS total_profit,
      COUNT(*) AS row_cnt
    FROM combined
    GROUP BY ROLLUP(s_store_name, i_category)
  )
SELECT
  f.s_store_name,
  f.i_category,
  f.total_sales,
  f.total_profit,
  f.row_cnt,
  top_cat.top_category
FROM final f
CROSS JOIN LATERAL (
  SELECT i_category AS top_category
  FROM base b
  WHERE b.s_store_name = f.s_store_name
  GROUP BY i_category
  ORDER BY SUM(b.ss_sales_price * b.ss_quantity) DESC
  LIMIT 1
) top_cat
WHERE (f.total_sales > 1000 OR f.total_profit > 100)
ORDER BY f.s_store_name NULLS LAST, f.i_category
LIMIT 100

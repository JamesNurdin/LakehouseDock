WITH sales_agg AS (
  SELECT
    cp.cp_department,
    i.i_brand,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amt
  FROM
    catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
      AND p.p_cost > 500
    LEFT JOIN web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
  WHERE
    t.t_meal_time = 'lunch'
    AND i.i_brand = 'BrandX'
    AND w.w_state = 'CA'
    AND cd.cd_gender = 'M'
  GROUP BY
    cp.cp_department,
    i.i_brand
)
SELECT
  cp_department,
  i_brand,
  total_profit,
  total_return_amt,
  ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank,
  CASE WHEN total_return_amt > 1000 THEN 'High' ELSE 'Low' END AS return_level
FROM sales_agg
ORDER BY profit_rank
LIMIT 100

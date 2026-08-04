WITH
  sales_agg AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_sold_date_sk,
      cs.cs_warehouse_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_promo_sk,
      SUM(cs.cs_quantity) AS sum_qty,
      SUM(cs.cs_net_paid) AS sum_net_paid
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
      AND cs.cs_net_paid > 0
    GROUP BY
      cs.cs_item_sk,
      cs.cs_sold_date_sk,
      cs.cs_warehouse_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_promo_sk
  ),
  returns_agg AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_returned_date_sk,
      cr.cr_warehouse_sk,
      cr.cr_refunded_hdemo_sk,
      SUM(cr.cr_return_amount) AS sum_return_amt
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
    GROUP BY
      cr.cr_item_sk,
      cr.cr_returned_date_sk,
      cr.cr_warehouse_sk,
      cr.cr_refunded_hdemo_sk
  ),
  base_union AS (
    SELECT
      d.d_year,
      i.i_category,
      w.w_warehouse_name,
      hd.hd_buy_potential,
      ib.ib_upper_bound,
      p.p_promo_sk,
      sa.sum_qty,
      ra.sum_return_amt,
      wr_l.web_ret_sum,
      CASE WHEN ib.ib_upper_bound IS NULL THEN 'Unknown' ELSE CAST(ib.ib_upper_bound AS varchar) END AS income_upper
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra
      ON sa.cs_item_sk = ra.cr_item_sk
     AND sa.cs_sold_date_sk = ra.cr_returned_date_sk
    JOIN date_dim d
      ON d.d_date_sk = COALESCE(sa.cs_sold_date_sk, ra.cr_returned_date_sk)
    JOIN item i
      ON i.i_item_sk = COALESCE(sa.cs_item_sk, ra.cr_item_sk)
    LEFT JOIN warehouse w
      ON w.w_warehouse_sk = COALESCE(sa.cs_warehouse_sk, ra.cr_warehouse_sk)
    LEFT JOIN household_demographics hd
      ON hd.hd_demo_sk = COALESCE(sa.cs_bill_hdemo_sk, ra.cr_refunded_hdemo_sk)
    LEFT JOIN income_band ib
      ON ib.ib_income_band_sk = hd.hd_income_band_sk
    LEFT JOIN promotion p
      ON p.p_promo_sk = sa.cs_promo_sk
    LEFT JOIN LATERAL (
      SELECT SUM(wr.wr_return_amt) AS web_ret_sum
      FROM web_returns wr
      JOIN web_page wp ON wp.wp_web_page_sk = wr.wr_web_page_sk
      WHERE wr.wr_item_sk = i.i_item_sk
        AND wp.wp_autogen_flag = 'Y'
    ) wr_l ON TRUE
    LEFT JOIN web_site ws
      ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2001
      AND i.i_category IS NOT NULL
      AND w.w_state = 'CA'
      AND hd.hd_buy_potential = '0-500'
      AND ib.ib_lower_bound >= 20000
      AND p.p_channel_radio = 'N'
      AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
      )
    UNION DISTINCT
    SELECT
      d.d_year,
      i.i_category,
      w.w_warehouse_name,
      hd.hd_buy_potential,
      ib.ib_upper_bound,
      p.p_promo_sk,
      sa.sum_qty,
      ra.sum_return_amt,
      wr_l.web_ret_sum,
      CASE WHEN ib.ib_upper_bound IS NULL THEN 'Unknown' ELSE CAST(ib.ib_upper_bound AS varchar) END
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra
      ON sa.cs_item_sk = ra.cr_item_sk
     AND sa.cs_sold_date_sk = ra.cr_returned_date_sk
    JOIN date_dim d
      ON d.d_date_sk = COALESCE(sa.cs_sold_date_sk, ra.cr_returned_date_sk)
    JOIN item i
      ON i.i_item_sk = COALESCE(sa.cs_item_sk, ra.cr_item_sk)
    LEFT JOIN warehouse w
      ON w.w_warehouse_sk = COALESCE(sa.cs_warehouse_sk, ra.cr_warehouse_sk)
    LEFT JOIN household_demographics hd
      ON hd.hd_demo_sk = COALESCE(sa.cs_bill_hdemo_sk, ra.cr_refunded_hdemo_sk)
    LEFT JOIN income_band ib
      ON ib.ib_income_band_sk = hd.hd_income_band_sk
    LEFT JOIN promotion p
      ON p.p_promo_sk = sa.cs_promo_sk
    LEFT JOIN LATERAL (
      SELECT SUM(wr.wr_return_amt) AS web_ret_sum
      FROM web_returns wr
      JOIN web_page wp ON wp.wp_web_page_sk = wr.wr_web_page_sk
      WHERE wr.wr_item_sk = i.i_item_sk
        AND wp.wp_autogen_flag = 'N'
    ) wr_l ON TRUE
    LEFT JOIN web_site ws
      ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND i.i_category = 'Electronics'
      AND w.w_state = 'NY'
      AND hd.hd_buy_potential = '>10000'
      AND ib.ib_lower_bound >= 50000
      AND p.p_channel_radio = 'Y'
      AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
      )
  )
SELECT
  d_year,
  i_category,
  w_warehouse_name,
  SUM(sum_qty) AS total_qty,
  SUM(sum_return_amt) AS total_returns,
  SUM(web_ret_sum) AS total_web_returns,
  COUNT(DISTINCT p_promo_sk) AS distinct_promos,
  income_upper
FROM base_union
GROUP BY
  d_year,
  i_category,
  w_warehouse_name,
  income_upper
HAVING SUM(sum_qty) > 5000
ORDER BY total_qty DESC, d_year
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

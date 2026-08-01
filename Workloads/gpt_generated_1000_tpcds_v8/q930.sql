/* goal: Compare total return amounts and net loss by store (including stores with no returns) and by item category, combining store and web return data, while filtering out items that also appear in web returns, and enriching with catalog page descriptions. */
WITH
  sr_pre AS (
    SELECT
      s.s_store_id,
      s.s_store_name,
      i.i_category,
      d.d_year,
      SUM(sr.sr_return_amt)               AS total_return_amt,
      SUM(sr.sr_net_loss)                 AS total_net_loss,
      COUNT(*)                            AS return_cnt,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(sr.sr_net_loss) DESC) AS loss_rank,
      cp.cp_description
    FROM store_returns sr
    RIGHT JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_page cp
      ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN LATERAL (
        SELECT avg(i2.i_current_price) AS avg_brand_price
        FROM item i2
        WHERE i2.i_brand = i.i_brand
    ) brand_stats ON true
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_item_sk = sr.sr_item_sk
          AND wr.wr_returned_date_sk = sr.sr_returned_date_sk
    )
    GROUP BY
      s.s_store_id,
      s.s_store_name,
      i.i_category,
      d.d_year,
      cp.cp_description,
      brand_stats.avg_brand_price
    HAVING SUM(sr.sr_return_amt) > 1000
  ),
  wr_pre AS (
    SELECT
      NULL AS s_store_id,
      NULL AS s_store_name,
      i.i_category,
      d.d_year,
      SUM(wr.wr_return_amt)               AS total_return_amt,
      SUM(wr.wr_net_loss)                 AS total_net_loss,
      COUNT(*)                            AS return_cnt,
      ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(wr.wr_net_loss) DESC) AS loss_rank,
      cp2.cp_description
    FROM web_returns wr
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c_ref
      ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
    LEFT JOIN LATERAL (
        SELECT max(cp_inner.cp_description) AS cp_description
        FROM catalog_page cp_inner
        WHERE cp_inner.cp_start_date_sk <= d.d_date_sk
          AND cp_inner.cp_end_date_sk   >= d.d_date_sk
        LIMIT 1
    ) cp2 ON true
    GROUP BY
      i.i_category,
      d.d_year,
      cp2.cp_description
  )
SELECT *
FROM (
  SELECT * FROM sr_pre
  UNION
  SELECT * FROM wr_pre
) combined
ORDER BY total_net_loss DESC
LIMIT 100

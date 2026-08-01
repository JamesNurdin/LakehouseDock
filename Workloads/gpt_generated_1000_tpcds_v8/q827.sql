WITH
  -- Sales aggregation with rollup and window rank
  sales_agg AS (
    SELECT
      ds.d_year,
      ss.ss_store_sk,
      SUM(ss.ss_net_profit) AS store_profit,
      RANK() OVER (PARTITION BY ss.ss_store_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
    FROM store_sales ss
    JOIN date_dim ds            ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN time_dim td            ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd   ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd  ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p                ON ss.ss_promo_sk = p.p_promo_sk
    JOIN income_band ib             ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ds.d_year = 2002                                 -- filter 1
      AND hd.hd_buy_potential = '1001-5000'                -- filter 2
      AND p.p_channel_press = 'N'                         -- filter 3
      AND ib.ib_upper_bound >= 50000                      -- filter 4
      AND ss.ss_net_profit > 0                            -- filter 5
    GROUP BY ROLLUP (ds.d_year, ss.ss_store_sk)
  ),

  -- Catalog returns aggregation
  returns_agg AS (
    SELECT
      dr.d_year,
      cr.cr_returned_date_sk,
      SUM(cr.cr_net_loss) AS total_return_loss,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim dr           ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN time_dim tr           ON cr.cr_returned_time_sk = tr.t_time_sk
    JOIN customer_demographics cd2 ON cr.cr_refunded_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON cr.cr_refunded_hdemo_sk = hd2.hd_demo_sk
    JOIN customer_address ca2       ON cr.cr_refunded_addr_sk = ca2.ca_address_sk
    JOIN reason r                  ON cr.cr_reason_sk = r.r_reason_sk
    WHERE dr.d_year = 2002                                 -- filter 6
      AND r.r_reason_desc LIKE '%Defect%'
    GROUP BY dr.d_year, cr.cr_returned_date_sk
  ),

  -- Web returns aggregation (joins all remaining tables)
  web_returns_agg AS (
    SELECT
      dw.d_year,
      wr.wr_returned_date_sk,
      SUM(wr.wr_net_loss) AS web_return_loss
    FROM web_returns wr
    JOIN date_dim dw           ON wr.wr_returned_date_sk = dw.d_date_sk
    JOIN time_dim tw           ON wr.wr_returned_time_sk = tw.t_time_sk
    JOIN customer_demographics cd3 ON wr.wr_refunded_cdemo_sk = cd3.cd_demo_sk
    JOIN household_demographics hd3 ON wr.wr_refunded_hdemo_sk = hd3.hd_demo_sk
    JOIN customer_address ca3       ON wr.wr_refunded_addr_sk = ca3.ca_address_sk
    JOIN reason r2                 ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE dw.d_year = 2002
      AND r2.r_reason_desc LIKE '%Defect%'
    GROUP BY dw.d_year, wr.wr_returned_date_sk
  ),

  -- Union of sales orders and catalog returns (dedup via UNION DISTINCT)
  combined AS (
    SELECT
      ds.d_year,
      ss.ss_store_sk,
      ss.ss_ticket_number AS order_number,
      SUM(ss.ss_net_profit) AS profit,
      NULL AS loss
    FROM store_sales ss
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    WHERE ds.d_year = 2002
    GROUP BY ds.d_year, ss.ss_store_sk, ss.ss_ticket_number

    UNION

    SELECT
      dr.d_year,
      NULL AS ss_store_sk,
      cr.cr_order_number AS order_number,
      NULL AS profit,
      SUM(cr.cr_net_loss) AS loss
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    WHERE dr.d_year = 2002
    GROUP BY dr.d_year, cr.cr_order_number
  ),

  -- Row numbering for pagination
  numbered AS (
    SELECT
      c.*, 
      ROW_NUMBER() OVER (ORDER BY COALESCE(c.profit,0) DESC) AS rn
    FROM combined c
  ),

  -- Correlated sub‑query to fetch a later return amount per order
  enriched AS (
    SELECT
      n.*,
      (SELECT MAX(cr2.cr_return_amount)
         FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = n.order_number
          AND cr2.cr_returned_date_sk > (
                SELECT d_date_sk FROM date_dim WHERE d_year = 2002 LIMIT 1
              )
      ) AS max_later_return_amount
    FROM numbered n
    WHERE n.rn <= 500                     -- additional filter predicate
  )

SELECT *
FROM (
  SELECT
    e.d_year,
    e.ss_store_sk,
    e.order_number,
    e.profit,
    e.loss,
    e.max_later_return_amount,
    e.rn
  FROM enriched e
  CROSS JOIN UNNEST(ARRAY[1,2]) AS t(multiplier)   -- cross join with a small computed set
  WHERE e.profit IS NOT NULL                      -- filter 7
    AND e.loss IS NULL                            -- filter 8
    AND e.rn BETWEEN 1 AND 400                    -- filter 9
) a
EXCEPT
SELECT *
FROM (
  SELECT
    e2.d_year,
    e2.ss_store_sk,
    e2.order_number,
    e2.profit,
    e2.loss,
    e2.max_later_return_amount,
    e2.rn
  FROM enriched e2
  WHERE e2.loss IS NOT NULL                       -- filter 10
) b
ORDER BY rn
OFFSET 10
LIMIT 100

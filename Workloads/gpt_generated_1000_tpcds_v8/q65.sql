WITH
  -- Sample a fraction of the fact table to keep the query lightweight
  sales_sample AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)   -- roughly 10% of rows
  ),

  -- Core join that pulls in every selected table (16 total) and applies the anti‑join
  base AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_cdemo_sk,
      ss.ss_hdemo_sk,
      ss.ss_store_sk,
      ss.ss_sales_price,
      d.d_year               AS year,
      t.t_hour               AS hour,
      i.i_item_id,
      i.i_current_price,
      c.c_customer_id,
      cd.cd_gender,
      hd.hd_buy_potential,
      s.s_store_name         AS store_name,
      w.w_warehouse_name,
      r.r_reason_desc,
      cp.cp_catalog_page_number,
      wr.wr_return_quantity,
      ws.web_name,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY ss.ss_sales_price DESC) AS rn_store_sales
    FROM sales_sample ss
    /* 1 */ JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    /* 2 */ JOIN time_dim t               ON ss.ss_sold_time_sk = t.t_time_sk
    /* 3 */ JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
    /* 4 */ JOIN customer c               ON ss.ss_customer_sk = c.c_customer_sk
    /* 5 */ JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    /* 6 */ JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    /* 7 */ JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
    /* 8 */ JOIN catalog_returns cr       ON ss.ss_item_sk = cr.cr_item_sk
                                         AND cr.cr_returned_date_sk = ss.ss_sold_date_sk
    /* 9 */ JOIN catalog_page cp          ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    /*10 */ JOIN reason r                 ON cr.cr_reason_sk = r.r_reason_sk
    /*11 */ JOIN warehouse w              ON cr.cr_warehouse_sk = w.w_warehouse_sk
    /*12 */ JOIN web_returns wr          ON ss.ss_item_sk = wr.wr_item_sk
                                         AND wr.wr_returned_date_sk = ss.ss_sold_date_sk
    /*13 */ JOIN web_page wp              ON wr.wr_web_page_sk = wp.wp_web_page_sk
    /*14 */ JOIN web_site ws              ON ws.web_open_date_sk = ss.ss_sold_date_sk
    /*15 */ JOIN inventory inv            ON inv.inv_item_sk = i.i_item_sk
                                         AND inv.inv_date_sk = ss.ss_sold_date_sk
    /*16 */ JOIN warehouse w2             ON inv.inv_warehouse_sk = w2.w_warehouse_sk
    WHERE NOT EXISTS (
      SELECT 1
      FROM catalog_returns crx
      WHERE crx.cr_item_sk = ss.ss_item_sk
        AND crx.cr_returned_date_sk = ss.ss_sold_date_sk
    )
  ),

  -- First branch of the UNION – sales for year 2001
  q1 AS (
    SELECT
      store_name,
      year,
      SUM(ss_sales_price) AS total_sales,
      COUNT(*)           AS trx_cnt,
      MAX(rn_store_sales) AS max_rank
    FROM base
    WHERE year = 2001
    GROUP BY store_name, year
  ),

  -- Second branch of the UNION – sales for year 2002
  q2 AS (
    SELECT
      store_name,
      year,
      SUM(ss_sales_price) AS total_sales,
      COUNT(*)           AS trx_cnt,
      MAX(rn_store_sales) AS max_rank
    FROM base
    WHERE year = 2002
    GROUP BY store_name, year
  )

SELECT
  store_name,
  year,
  SUM(total_sales) AS agg_sales,
  SUM(trx_cnt)     AS agg_trx,
  MAX(max_rank)   AS highest_rank
FROM (
  SELECT * FROM q1
  UNION DISTINCT
  SELECT * FROM q2
) u
GROUP BY store_name, year
ORDER BY agg_sales DESC
LIMIT 100

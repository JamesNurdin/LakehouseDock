/*
  Goal: Produce yearly sales and profit totals broken down by ship mode, promotion and household income band across catalog and web channels.
  The query joins all ten selected tables, re‑uses date_dim under several aliases, performs a FULL OUTER JOIN between promotion and date_dim,
  uses RIGHT OUTER JOINs to retain all ship modes, adds a correlated scalar sub‑query for yearly return amounts, applies a CASE expression,
  combines catalog and web results with UNION DISTINCT, and returns subtotals and a grand total with GROUP BY ROLLUP.  Results are ordered and limited.
*/
WITH
  -- Full outer join of promotions to their start dates (keeps promotions without dates and dates without promotions)
  promo_dates AS (
    SELECT
      p.p_promo_sk,
      p.p_promo_name,
      d.d_year   AS start_year,
      d.d_date   AS start_date
    FROM promotion p
    FULL OUTER JOIN date_dim d
      ON p.p_start_date_sk = d.d_date_sk
  )
,
  -- Union of catalog and web sales, each enriched with the same dimensional attributes
  unified_sales AS (
    -- Catalog sales side
    SELECT
      d_sold.d_year                                          AS year,
      sm.sm_ship_mode_id                                    AS ship_mode_id,
      pd.p_promo_name                                       AS promo_name,
      CAST(ib.ib_lower_bound AS VARCHAR) || '-' || CAST(ib.ib_upper_bound AS VARCHAR) AS income_band_range,
      SUM(cs.cs_ext_sales_price)                            AS total_sales,
      SUM(cs.cs_net_profit)                                 AS total_profit,
      CASE WHEN SUM(cs.cs_ext_sales_price) > 1000000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
      (
        SELECT SUM(sr.sr_return_amt)
        FROM store_returns sr
        JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
        WHERE d_ret.d_year = d_sold.d_year
      )                                                    AS yearly_return_total
    FROM catalog_sales cs
    RIGHT OUTER JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
      ON cs.cs_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN income_band ib
      ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN promo_dates pd
      ON cs.cs_promo_sk = pd.p_promo_sk
    GROUP BY ROLLUP (
      d_sold.d_year,
      sm.sm_ship_mode_id,
      pd.p_promo_name,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    )

    UNION DISTINCT

    -- Web sales side
    SELECT
      d_sold.d_year                                          AS year,
      sm.sm_ship_mode_id                                    AS ship_mode_id,
      pd.p_promo_name                                       AS promo_name,
      CAST(ib.ib_lower_bound AS VARCHAR) || '-' || CAST(ib.ib_upper_bound AS VARCHAR) AS income_band_range,
      SUM(ws.ws_ext_sales_price)                            AS total_sales,
      SUM(ws.ws_net_profit)                                 AS total_profit,
      CASE WHEN SUM(ws.ws_ext_sales_price) > 1000000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
      (
        SELECT SUM(sr.sr_return_amt)
        FROM store_returns sr
        JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
        WHERE d_ret.d_year = d_sold.d_year
      )                                                    AS yearly_return_total
    FROM web_sales ws
    RIGHT OUTER JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
      ON ws.ws_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN household_demographics hd_bill
      ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN income_band ib
      ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN promo_dates pd
      ON ws.ws_promo_sk = pd.p_promo_sk
    LEFT JOIN web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN date_dim d_site_open
      ON we.web_open_date_sk = d_site_open.d_date_sk
    LEFT JOIN date_dim d_site_close
      ON we.web_close_date_sk = d_site_close.d_date_sk
    GROUP BY ROLLUP (
      d_sold.d_year,
      sm.sm_ship_mode_id,
      pd.p_promo_name,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    )
  )
SELECT
  year,
  ship_mode_id,
  promo_name,
  income_band_range,
  total_sales,
  total_profit,
  sales_category,
  yearly_return_total
FROM unified_sales
ORDER BY year DESC, ship_mode_id
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

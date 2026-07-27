WITH sales_returns AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        i.i_item_id,
        d.d_date,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001                     -- filter 1: year
      AND t.t_hour BETWEEN 8 AND 18           -- filter 2: business hours
      AND i.i_current_price > 50              -- filter 3: price threshold
      AND hd.hd_income_band_sk IN (9, 10)      -- filter 4: income band
      AND ca.ca_state = 'TX'                  -- filter 5: state
    GROUP BY ss.ss_item_sk, i.i_item_id, d.d_date
),
returns_agg AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        d_ret.d_date,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN item i_ret ON cr.cr_item_sk = i_ret.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE EXISTS (
        SELECT 1
        FROM ship_mode sm
        WHERE sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
          AND sm.sm_contract = 'P7FBIt8yd'
    )
    GROUP BY cr.cr_item_sk, d_ret.d_date
)
SELECT DISTINCT
    sr.i_item_id,
    sr.d_date,
    sr.total_sales,
    ra.total_return_amount,
    (sr.total_sales - COALESCE(ra.total_return_amount, 0)) AS net_sales,
    sr.total_profit,
    sr.profit_category,
    sr.distinct_tickets
FROM sales_returns sr
LEFT JOIN returns_agg ra
    ON sr.item_sk = ra.item_sk
   AND sr.d_date = ra.d_date
WHERE (sr.total_sales - COALESCE(ra.total_return_amount, 0)) > 5000
ORDER BY net_sales DESC
LIMIT 100

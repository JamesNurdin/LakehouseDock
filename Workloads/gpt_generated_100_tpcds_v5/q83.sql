WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_store_sk,
        sr.sr_addr_sk,
        sr.sr_hdemo_sk,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        d.d_year,
        d.d_quarter_name,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        ca.ca_state,
        s.s_state,
        s.s_market_desc,
        cp.cp_department,
        wp.wp_link_count,
        ws.web_name,
        p.p_discount_active,
        p.p_cost
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND s.s_state = 'CA'
      AND hd.hd_income_band_sk IN (11, 12, 17)
      AND p.p_discount_active = 'Y'
      AND wp.wp_link_count > 5
),
agg AS (
    SELECT
        s_state,
        d_year,
        cp_department,
        CASE WHEN hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END AS vehicle_category,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_tax) AS avg_return_tax,
        COUNT(DISTINCT sr_ticket_number) AS distinct_tickets,
        MAX(p_cost) AS max_promo_cost,
        (SELECT MAX(p_cost) FROM promotion WHERE p_discount_active = 'Y') AS overall_max_active_promo_cost,
        COUNT(*) FILTER (WHERE sr_return_quantity > 1) AS multi_item_returns
    FROM base
    GROUP BY s_state, d_year, cp_department, hd_vehicle_count
    HAVING SUM(sr_return_amt) > 1000
)
SELECT
    s_state,
    d_year,
    cp_department,
    vehicle_category,
    total_return_amt,
    avg_return_tax,
    distinct_tickets,
    max_promo_cost,
    overall_max_active_promo_cost,
    multi_item_returns,
    SUM(total_return_amt) OVER (
        PARTITION BY s_state
        ORDER BY total_return_amt DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_return_by_state
FROM agg
ORDER BY total_return_amt DESC
LIMIT 100

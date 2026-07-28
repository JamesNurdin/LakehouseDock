WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_sales_price,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2002
      AND s.s_state = 'CA'
      AND s.s_market_manager = 'James Irvin'
      AND p.p_channel_catalog = 'N'
      AND p.p_response_target = 1
      AND ss.ss_quantity > 0
),
agg_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        i.i_brand,
        ib.ib_income_band_sk,
        SUM(fs.ss_ext_sales_price) AS total_sales,
        SUM(fs.ss_quantity) AS total_quantity,
        AVG(fs.ss_sales_price) AS avg_unit_price,
        COUNT(DISTINCT fs.ss_ticket_number) AS distinct_tickets
    FROM filtered_sales fs
    JOIN date_dim d ON fs.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON fs.ss_store_sk = s.s_store_sk
    JOIN item i ON fs.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON fs.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON fs.ss_promo_sk = p.p_promo_sk
    JOIN date_dim pd_start ON p.p_start_date_sk = pd_start.d_date_sk
    JOIN date_dim pd_end   ON p.p_end_date_sk   = pd_end.d_date_sk
    WHERE i.i_current_price > 20.00
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_lower_bound >= 50000
      AND pd_start.d_year = 2002
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        i.i_brand,
        ib.ib_income_band_sk
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.d_year,
    a.i_brand,
    a.ib_income_band_sk,
    a.total_sales,
    a.total_quantity,
    a.avg_unit_price,
    a.distinct_tickets,
    RANK() OVER (ORDER BY a.total_sales DESC) AS sales_rank
FROM agg_sales a
ORDER BY a.total_sales DESC
LIMIT 100

WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_brand,
        i.i_category,
        s.s_state,
        ca.ca_country,
        p.p_response_target,
        cs.cs_quantity,
        cs.cs_net_paid,
        ss.ss_quantity,
        ss.ss_net_paid,
        ws.ws_quantity,
        ws.ws_net_paid,
        iinv.inv_quantity_on_hand
    FROM date_dim d
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN inventory iinv ON iinv.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON i.i_item_sk = ss.ss_item_sk
    JOIN ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    JOIN customer_address ca ON ca.ca_address_sk = ss.ss_addr_sk
    WHERE
        d.d_year = 2001
        AND d.d_month_seq BETWEEN 1200 AND 1215
        AND i.i_brand = 'Brand#12'
        AND p.p_response_target >= 1
        AND s.s_state = 'CA'
        AND ca.ca_country = 'United States'
        AND cs.cs_quantity > 0
        AND ss.ss_quantity > 0
        AND ws.ws_quantity > 0
        AND iinv.inv_quantity_on_hand > 0
),
aggregated AS (
    SELECT
        d_year,
        i_brand,
        i_category,
        SUM(total_sales) AS sum_total_sales,
        SUM(total_quantity) AS sum_total_quantity,
        COUNT(*) AS cnt
    FROM (
        SELECT
            d_year,
            i_brand,
            i_category,
            (cs_net_paid + ss_net_paid + ws_net_paid) AS total_sales,
            (cs_quantity + ss_quantity + ws_quantity) AS total_quantity
        FROM base
    ) t
    GROUP BY ROLLUP (d_year, i_brand, i_category)
    HAVING SUM(total_sales) > 10000
)
SELECT
    d_year,
    i_brand,
    i_category,
    sum_total_sales,
    sum_total_quantity,
    cnt,
    ROW_NUMBER() OVER (ORDER BY sum_total_sales DESC) AS row_num
FROM aggregated
ORDER BY sum_total_sales DESC
LIMIT 100

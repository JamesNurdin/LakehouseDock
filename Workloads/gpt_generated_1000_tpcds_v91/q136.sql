WITH sr_sample AS (
    SELECT *
    FROM store_returns TABLESAMPLE BERNOULLI (10)
),
joined_all AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_addr_sk,
        sr.sr_store_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        d_ret.d_year,
        d_ret.d_holiday,
        t.t_hour,
        i.i_brand,
        i.i_color,
        i.i_formulation,
        i.i_current_price,
        s.s_store_name,
        s.s_state,
        s.s_gmt_offset,
        ca.ca_city,
        ca.ca_state,
        inv.inv_quantity_on_hand,
        cp.cp_department,
        cp.cp_catalog_page_number
    FROM sr_sample sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN inventory inv ON sr.sr_item_sk = inv.inv_item_sk
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_ret.d_date_sk
        AND cp.cp_end_date_sk = d_ret.d_date_sk
    WHERE i.i_color = 'snow'
      AND s.s_state = 'CA'
      AND d_ret.d_year = 2001
      AND cp.cp_department = 'Electronics'
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    s_store_name,
    d_year,
    i_brand,
    total_net_loss,
    total_quantity_on_hand,
    return_cnt,
    holiday_return_cnt,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_net_loss DESC) AS brand_rank_within_store
FROM (
    SELECT
        s_store_name,
        d_year,
        i_brand,
        SUM(sr_net_loss) AS total_net_loss,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(*) AS return_cnt,
        SUM(CASE WHEN d_holiday = 'Y' THEN 1 ELSE 0 END) AS holiday_return_cnt
    FROM joined_all
    GROUP BY ROLLUP (s_store_name, d_year, i_brand)
    HAVING SUM(sr_net_loss) IS NOT NULL
) agg
ORDER BY total_net_loss DESC
LIMIT 100

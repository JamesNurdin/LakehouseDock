WITH joined AS (
    SELECT
        wr.wr_return_amt,
        i.i_item_sk,
        i.i_brand,
        i.i_color,
        inv.inv_quantity_on_hand,
        d.d_year,
        d.d_dow,
        d.d_month_seq,
        s.s_store_name,
        s.s_division_name,
        s.s_market_manager,
        s.s_state
    FROM web_returns wr
    FULL OUTER JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    INNER JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    INNER JOIN date_dim d
        ON inv.inv_date_sk = d.d_date_sk
    INNER JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND d.d_dow IN (1, 2, 3)
      AND i.i_brand = 'Brand#12'
      AND inv.inv_quantity_on_hand > 100
      AND s.s_market_manager = 'Thomas Pollack'
      AND s.s_state = 'CA'
)
SELECT
    s_store_name,
    d_year,
    total_return,
    RANK() OVER (PARTITION BY s_division_name ORDER BY total_return DESC) AS division_return_rank,
    CASE WHEN total_return > 1000 THEN 'High' ELSE 'Low' END AS return_category
FROM (
    SELECT
        s_store_name,
        d_year,
        s_division_name,
        SUM(wr_return_amt) AS total_return
    FROM joined
    GROUP BY s_store_name, d_year, s_division_name
) agg
ORDER BY division_return_rank, total_return DESC
LIMIT 100

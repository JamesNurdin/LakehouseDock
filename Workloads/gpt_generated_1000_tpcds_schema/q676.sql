WITH sales_agg AS (
    SELECT
        d.d_date_id,
        i.i_item_id,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_net_profit) AS profit_amount,
        COUNT(*) AS sales_cnt
    FROM
        date_dim d
        RIGHT OUTER JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE
        d.d_year = 2001
        AND i.i_class_id IN (4, 6, 9)
        AND ss.ss_coupon_amt > 100
    GROUP BY
        d.d_date_id,
        i.i_item_id
),
returns_agg AS (
    SELECT
        d.d_date_id,
        i.i_item_id,
        SUM(wr.wr_return_amt_inc_tax) AS return_amount,
        COUNT(*) AS return_cnt
    FROM
        date_dim d
        JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE
        d.d_year = 2001
        AND wr.wr_return_amt_inc_tax < 1000
        AND i.i_class_id IN (4, 6, 9)
    GROUP BY
        d.d_date_id,
        i.i_item_id
),
inventory_lateral AS (
    SELECT
        d.d_date_id,
        i.i_item_id,
        inv_tot.total_inv
    FROM
        date_dim d
        JOIN item i ON 1 = 1
        LEFT JOIN LATERAL (
            SELECT SUM(inv.inv_quantity_on_hand) AS total_inv
            FROM inventory inv
            WHERE inv.inv_date_sk = d.d_date_sk
              AND inv.inv_item_sk = i.i_item_sk
              AND inv.inv_quantity_on_hand > 500
        ) inv_tot ON TRUE
    WHERE
        d.d_year = 2001
        AND i.i_class_id IN (4, 6, 9)
),
item_intersect AS (
    SELECT DISTINCT i_item_id FROM sales_agg
    INTERSECT
    SELECT DISTINCT i_item_id FROM returns_agg
)
SELECT
    s.d_date_id,
    s.i_item_id,
    s.sales_amount,
    r.return_amount,
    iinv.total_inv,
    (s.sales_amount - COALESCE(r.return_amount, 0)) AS net_sales,
    s.profit_amount / NULLIF(s.sales_cnt, 0) AS avg_profit_per_sale
FROM
    sales_agg s
    LEFT JOIN returns_agg r
        ON s.d_date_id = r.d_date_id AND s.i_item_id = r.i_item_id
    LEFT JOIN inventory_lateral iinv
        ON s.d_date_id = iinv.d_date_id AND s.i_item_id = iinv.i_item_id
    INNER JOIN item_intersect ii
        ON s.i_item_id = ii.i_item_id
WHERE
    iinv.total_inv IS NOT NULL
    AND s.sales_amount > 1000
ORDER BY
    net_sales DESC,
    s.d_date_id
LIMIT 100

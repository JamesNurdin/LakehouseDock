SELECT *
FROM (
    /* Sales side */
    SELECT
        d.d_year,
        i.i_item_id,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS metric_amount,
        COALESCE(SUM(cs.cs_quantity), 0)       AS metric_quantity,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(cs.cs_ext_sales_price), 0) DESC) AS rn
    FROM catalog_sales cs
    RIGHT JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk          -- fact right‑joined to dimension
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, i.i_item_id

    UNION ALL

    /* Returns side */
    SELECT
        d.d_year,
        i.i_item_id,
        COALESCE(SUM(wr.wr_return_amt), 0) AS metric_amount,
        COALESCE(COUNT(wr.wr_return_quantity), 0) AS metric_quantity,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(wr.wr_return_amt), 0) DESC) AS rn
    FROM promotion p
    FULL OUTER JOIN item i
        ON p.p_item_sk = i.i_item_sk                 -- keep unmatched promotions and items
    LEFT JOIN web_returns wr
        ON i.i_item_sk = wr.wr_item_sk
    LEFT JOIN date_dim d
        ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 OR d.d_year IS NULL
    GROUP BY d.d_year, i.i_item_id
) AS combined
ORDER BY metric_amount DESC
LIMIT 100

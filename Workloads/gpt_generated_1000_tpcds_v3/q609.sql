WITH sales_returns_agg AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        d.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_quantity) AS total_sales_quantity,
        SUM(cs.cs_net_profit) AS total_sales_net_profit,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_net_loss) AS total_return_net_loss
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'               -- filter 1: specific year
        AND cp.cp_catalog_page_number BETWEEN 10 AND 20                      -- filter 2: page number range
        AND cs.cs_list_price > 50.00                                         -- filter 3: high list price
        AND sr.sr_store_credit > 100.00                                      -- filter 4: significant store credit
        AND cp.cp_type = 'PROMO'                                             -- filter 5: promotional pages
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        d.d_year
)
SELECT
    cp_catalog_page_id,
    cp_catalog_page_number,
    d_year,
    total_sales_amount,
    total_return_amount,
    net_profit_after_returns,
    profit_margin,
    avg_profit_per_sale
FROM (
    SELECT
        cp_catalog_page_id,
        cp_catalog_page_number,
        d_year,
        total_sales_amount,
        total_return_amount,
        total_sales_net_profit - total_return_net_loss AS net_profit_after_returns,
        CASE WHEN total_sales_amount > 0 THEN (total_sales_net_profit - total_return_net_loss) / total_sales_amount ELSE 0 END AS profit_margin,
        CASE WHEN total_sales_quantity > 0 THEN (total_sales_net_profit - total_return_net_loss) / total_sales_quantity ELSE 0 END AS avg_profit_per_sale
    FROM sales_returns_agg
) t
WHERE net_profit_after_returns > 0
ORDER BY profit_margin DESC, avg_profit_per_sale DESC

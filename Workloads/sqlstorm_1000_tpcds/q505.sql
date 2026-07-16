WITH
    sales_agg AS (
        SELECT
            COALESCE(cs.cs_sold_date_sk, ss.ss_sold_date_sk, ws.ws_sold_date_sk) AS sold_date_sk,
            COALESCE(cs.cs_item_sk, ss.ss_item_sk, ws.ws_item_sk) AS item_sk,
            SUM(COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_net_paid,
            SUM(COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)) AS total_net_profit,
            COUNT(DISTINCT COALESCE(cs.cs_order_number, ss.ss_ticket_number, ws.ws_order_number)) AS distinct_orders
        FROM
            catalog_sales cs
            FULL OUTER JOIN store_sales ss
                ON cs.cs_sold_date_sk = ss.ss_sold_date_sk
                AND cs.cs_item_sk = ss.ss_item_sk
            FULL OUTER JOIN web_sales ws
                ON COALESCE(cs.cs_sold_date_sk, ss.ss_sold_date_sk) = ws.ws_sold_date_sk
                AND COALESCE(cs.cs_item_sk, ss.ss_item_sk) = ws.ws_item_sk
        GROUP BY
            1, 2
    ),
    returns_agg AS (
        SELECT
            COALESCE(cr.cr_returned_date_sk, sr.sr_returned_date_sk, wr.wr_returned_date_sk) AS returned_date_sk,
            COALESCE(cr.cr_item_sk, sr.sr_item_sk, wr.wr_item_sk) AS item_sk,
            SUM(COALESCE(cr.cr_net_loss, 0) + COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
            COUNT(*) AS return_cnt
        FROM
            catalog_returns cr
            FULL OUTER JOIN store_returns sr
                ON cr.cr_returned_date_sk = sr.sr_returned_date_sk
                AND cr.cr_item_sk = sr.sr_item_sk
            FULL OUTER JOIN web_returns wr
                ON COALESCE(cr.cr_returned_date_sk, sr.sr_returned_date_sk) = wr.wr_returned_date_sk
                AND COALESCE(cr.cr_item_sk, sr.sr_item_sk) = wr.wr_item_sk
        GROUP BY
            1, 2
    ),
    total_metrics AS (
        SELECT 'TotalSales' AS metric, SUM(total_net_paid) AS amount FROM sales_agg
        UNION ALL
        SELECT 'TotalReturns' AS metric, SUM(total_net_loss) AS amount FROM returns_agg
    ),
    agg_metrics AS (
        SELECT
            MAX(CASE WHEN metric = 'TotalSales' THEN amount END) AS total_sales_amount,
            MAX(CASE WHEN metric = 'TotalReturns' THEN amount END) AS total_returns_amount
        FROM total_metrics
    ),
    sales_returns AS (
        SELECT
            d.d_date AS sales_date,
            i.i_category,
            i.i_brand,
            COALESCE(sa.sold_date_sk, ra.returned_date_sk) AS date_sk,
            COALESCE(sa.item_sk, ra.item_sk) AS item_sk,
            COALESCE(sa.total_net_paid, 0) - COALESCE(ra.total_net_loss, 0) AS net_contribution,
            sa.total_net_paid,
            sa.total_net_profit,
            ra.total_net_loss,
            ROW_NUMBER() OVER (PARTITION BY d.d_year, i.i_category ORDER BY COALESCE(sa.total_net_paid, 0) DESC) AS category_profit_rank,
            CASE
                WHEN sa.total_net_paid IS NULL THEN 'NoSales'
                WHEN ra.total_net_loss IS NULL THEN 'NoReturns'
                ELSE 'Both'
            END AS sales_return_flag,
            COALESCE(i.i_product_name, 'Unknown') AS product_name,
            CONCAT(i.i_brand, ' - ', COALESCE(i.i_product_name, 'N/A')) AS branded_product_name,
            (
                SELECT
                    CASE WHEN SUM(cs.cs_net_paid) > 0 THEN 1 ELSE 0 END
                FROM
                    catalog_sales cs
                    JOIN date_dim d_prev ON cs.cs_sold_date_sk = d_prev.d_date_sk
                WHERE
                    cs.cs_item_sk = COALESCE(sa.item_sk, ra.item_sk)
                    AND d_prev.d_year = d.d_year
                    AND d_prev.d_month_seq = d.d_month_seq - 1
            ) AS top_last_month_flag,
            am.total_sales_amount,
            am.total_returns_amount
        FROM
            sales_agg sa
            FULL OUTER JOIN returns_agg ra
                ON sa.sold_date_sk = ra.returned_date_sk
                AND sa.item_sk = ra.item_sk
            LEFT JOIN date_dim d ON COALESCE(sa.sold_date_sk, ra.returned_date_sk) = d.d_date_sk
            LEFT JOIN item i ON COALESCE(sa.item_sk, ra.item_sk) = i.i_item_sk
            CROSS JOIN agg_metrics am
    ),
    final AS (
        SELECT
            sales_date,
            i_category,
            i_brand,
            product_name,
            branded_product_name,
            net_contribution,
            total_net_paid,
            total_net_profit,
            total_net_loss,
            category_profit_rank,
            sales_return_flag,
            top_last_month_flag,
            SUM(net_contribution) OVER (PARTITION BY i_category ORDER BY sales_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_contri,
            CASE
                WHEN total_net_profit IS NOT NULL AND total_net_profit <> 0 THEN total_net_profit / NULLIF(total_net_paid, 0)
                ELSE NULL
            END AS profit_to_sales_ratio,
            total_sales_amount,
            total_returns_amount
        FROM
            sales_returns
        WHERE
            sales_date >= DATE '2000-01-01'
            AND i_category IS NOT NULL
    )
SELECT
    sales_date,
    i_category,
    i_brand,
    branded_product_name,
    net_contribution,
    cum_net_contri,
    profit_to_sales_ratio,
    category_profit_rank,
    sales_return_flag,
    top_last_month_flag,
    total_sales_amount,
    total_returns_amount
FROM
    final
WHERE
    category_profit_rank <= 5
ORDER BY
    sales_date DESC,
    i_category,
    category_profit_rank

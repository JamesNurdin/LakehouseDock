/*
Goal: Produce a per‑income‑band summary of return activity across the three return channels (catalog, store, web).
The query joins all 15 selected TPC‑DS tables using only the allowed relationships, applies several filters, aggregates the data, creates a map of metrics per income band, expands that map with UNNEST, and finally orders and limits the result.
*/
WITH union_facts AS (
    -- Catalog returns (filtered)
    SELECT
        cr_returned_date_sk   AS return_date_sk,
        cr_returned_time_sk   AS return_time_sk,
        cr_item_sk            AS item_sk,
        cr_refunded_customer_sk AS customer_sk,
        cr_refunded_hdemo_sk  AS hdemo_sk,
        cr_refunded_addr_sk   AS addr_sk,
        NULL                  AS store_sk,
        cr_warehouse_sk       AS warehouse_sk,
        NULL                  AS web_page_sk,
        cr_return_amount      AS return_amount,
        cr_net_loss           AS net_loss
    FROM catalog_returns
    WHERE cr_return_amount > 100

    UNION DISTINCT

    -- Store returns (filtered)
    SELECT
        sr_returned_date_sk   AS return_date_sk,
        sr_return_time_sk     AS return_time_sk,
        sr_item_sk            AS item_sk,
        sr_customer_sk        AS customer_sk,
        sr_hdemo_sk           AS hdemo_sk,
        sr_addr_sk            AS addr_sk,
        sr_store_sk           AS store_sk,
        NULL                  AS warehouse_sk,
        NULL                  AS web_page_sk,
        sr_return_amt        AS return_amount,
        sr_net_loss           AS net_loss
    FROM store_returns
    WHERE sr_return_amt > 100

    UNION DISTINCT

    -- Web returns (filtered)
    SELECT
        wr_returned_date_sk   AS return_date_sk,
        wr_returned_time_sk   AS return_time_sk,
        wr_item_sk            AS item_sk,
        wr_refunded_customer_sk AS customer_sk,
        wr_refunded_hdemo_sk  AS hdemo_sk,
        wr_refunded_addr_sk   AS addr_sk,
        NULL                  AS store_sk,
        NULL                  AS warehouse_sk,
        wr_web_page_sk        AS web_page_sk,
        wr_return_amt        AS return_amount,
        wr_net_loss           AS net_loss
    FROM web_returns
    WHERE wr_return_amt > 100
),
joined AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(uf.net_loss)                         AS total_net_loss,
        COUNT(*)                                 AS txn_cnt,
        AVG(uf.return_amount)                    AS avg_return_amount,
        MAP(ARRAY['total_net_loss','txn_cnt'], ARRAY[SUM(uf.net_loss), COUNT(*)]) AS metrics_map
    FROM union_facts uf
    -- Date dimension (filter on year)
    JOIN date_dim d ON uf.return_date_sk = d.d_date_sk AND d.d_year = 2001
    -- Time dimension (filter on business hours)
    JOIN time_dim t ON uf.return_time_sk = t.t_time_sk AND t.t_hour BETWEEN 9 AND 17
    -- Item dimension (filter on a category)
    JOIN item i ON uf.item_sk = i.i_item_sk AND i.i_category = 'Electronics'
    -- Customer dimension
    JOIN customer c ON uf.customer_sk = c.c_customer_sk
    -- Customer address dimension (filter on state)
    LEFT JOIN customer_address ca ON uf.addr_sk = ca.ca_address_sk AND ca.ca_state = 'CA'
    -- Household demographics & income band
    JOIN household_demographics hd ON uf.hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    -- Warehouse (may be null for store/web returns)
    LEFT JOIN warehouse w ON uf.warehouse_sk = w.w_warehouse_sk
    -- Store dimension retained even if no store returns (RIGHT OUTER JOIN)
    RIGHT JOIN store s ON uf.store_sk = s.s_store_sk
    -- Inventory (joins through item and warehouse when both present)
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk AND w.w_warehouse_sk = inv.inv_warehouse_sk
    -- Web page dimension (only for web returns)
    LEFT JOIN web_page wp ON uf.web_page_sk = wp.wp_web_page_sk
    -- Web site dimension (joined through the date dimension)
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    HAVING SUM(uf.net_loss) > 0 AND COUNT(*) > 5
),
final AS (
    SELECT
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        metric_key,
        metric_value
    FROM joined
    CROSS JOIN UNNEST(metrics_map) AS t(metric_key, metric_value)
)
SELECT *
FROM final
ORDER BY ib_lower_bound, metric_key
LIMIT 100

WITH
    wr_sample AS (
        SELECT *
        FROM web_returns
        TABLESAMPLE BERNOULLI (10)
    ),
    base_query AS (
        SELECT
            d_ret.d_year AS year,
            s.s_state AS store_state,
            i.i_category AS item_category,
            cd_refunded.cd_gender AS refunded_gender,
            cd_returning.cd_gender AS returning_gender,
            SUM(wr.wr_return_amt) AS total_return_amt,
            SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
            COUNT(DISTINCT wr.wr_order_number) AS unique_orders
        FROM wr_sample wr
        JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN customer_demographics cd_refunded ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
        JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
        JOIN customer_demographics cd_returning ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
        JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
        JOIN store s ON TRUE
        JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
        JOIN web_site ws ON TRUE
        JOIN date_dim d_site_open ON ws.web_open_date_sk = d_site_open.d_date_sk
        JOIN date_dim d_site_close ON ws.web_close_date_sk = d_site_close.d_date_sk
        WHERE d_ret.d_year = 2000
        GROUP BY d_ret.d_year, s.s_state, i.i_category, cd_refunded.cd_gender, cd_returning.cd_gender
        HAVING SUM(wr.wr_return_amt) > 5000
    ),
    second_query AS (
        SELECT
            d_ret.d_year AS year,
            s.s_state AS store_state,
            i.i_category AS item_category,
            cd_refunded.cd_gender AS refunded_gender,
            cd_returning.cd_gender AS returning_gender,
            SUM(wr.wr_return_amt) AS total_return_amt,
            SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
            COUNT(DISTINCT wr.wr_order_number) AS unique_orders
        FROM wr_sample wr
        JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN customer_demographics cd_refunded ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
        JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
        JOIN customer_demographics cd_returning ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
        JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
        JOIN store s ON TRUE
        JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
        JOIN web_site ws ON TRUE
        JOIN date_dim d_site_open ON ws.web_open_date_sk = d_site_open.d_date_sk
        JOIN date_dim d_site_close ON ws.web_close_date_sk = d_site_close.d_date_sk
        WHERE d_ret.d_year = 2001
        GROUP BY d_ret.d_year, s.s_state, i.i_category, cd_refunded.cd_gender, cd_returning.cd_gender
        HAVING SUM(wr.wr_return_amt) > 5000
    )
SELECT
    year,
    store_state,
    item_category,
    refunded_gender,
    returning_gender,
    total_return_amt,
    total_inventory_qty,
    unique_orders,
    CASE WHEN total_return_amt > 100000 THEN 'HIGH' ELSE 'LOW' END AS return_class,
    RANK() OVER (ORDER BY total_return_amt DESC) AS return_rank,
    SUM(total_return_amt) OVER (PARTITION BY store_state) AS sum_return_by_state
FROM (
    SELECT * FROM base_query
    UNION
    SELECT * FROM second_query
) u
ORDER BY total_return_amt DESC
LIMIT 100

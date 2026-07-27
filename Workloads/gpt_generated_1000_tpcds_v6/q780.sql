WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_item_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_net_paid,
        ss.ss_quantity          AS ss_quantity,
        ss.ss_net_profit        AS ss_net_profit,
        ss.ss_net_paid          AS ss_net_paid
    FROM catalog_sales cs
    LEFT JOIN store_sales ss
        ON cs.cs_item_sk = ss.ss_item_sk
       AND cs.cs_sold_date_sk = ss.ss_sold_date_sk
    WHERE cs.cs_quantity > 0
),
agg AS (
    SELECT
        i.i_category,
        d_sold.d_year,
        SUM(sa.cs_net_profit + COALESCE(sa.ss_net_profit, 0)) AS total_profit,
        COUNT(DISTINCT i.i_item_sk)                       AS distinct_items
    FROM sales_base sa
    JOIN item i
        ON i.i_item_sk = sa.cs_item_sk
    JOIN date_dim d_sold
        ON sa.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON sa.cs_ship_date_sk = d_ship.d_date_sk
    JOIN catalog_page cp
        ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_page_start
        ON cp.cp_start_date_sk = d_page_start.d_date_sk
    JOIN date_dim d_page_end
        ON cp.cp_end_date_sk = d_page_end.d_date_sk
    JOIN customer_address ca_bill
        ON sa.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON sa.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sold.d_date_sk
    JOIN date_dim d_web_close
        ON ws.web_close_date_sk = d_web_close.d_date_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_date_sk = d_sold.d_date_sk
    WHERE EXISTS (
        SELECT 1
        FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk
          AND inv2.inv_quantity_on_hand > 0
          AND inv2.inv_date_sk = d_sold.d_date_sk
    )
    GROUP BY i.i_category, d_sold.d_year
)
SELECT
    a.i_category,
    a.d_year,
    a.total_profit,
    a.distinct_items,
    CASE
        WHEN a.total_profit > 100000 THEN 'HIGH'
        WHEN a.total_profit > 50000  THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_tier,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_profit DESC) AS profit_rank_year
FROM agg a
ORDER BY a.total_profit DESC
LIMIT 100

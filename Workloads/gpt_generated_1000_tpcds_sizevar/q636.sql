WITH inv_sample AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),
sales_full AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
)
SELECT
    i.i_category AS category,
    d_sold.d_year AS sales_year,
    COUNT(DISTINCT sf.ss_ticket_number) AS total_tickets,
    SUM(sf.ss_ext_sales_price) AS total_sales,
    SUM(CASE WHEN sf.sr_return_quantity IS NULL THEN 0 ELSE sf.sr_return_quantity END) AS total_returns,
    (SUM(sf.ss_net_profit) - COALESCE(SUM(sf.sr_net_loss), 0)) AS net_profit,
    AVG(
        CASE
            WHEN p.p_discount_active = 'Y' THEN sf.ss_ext_sales_price * 0.9
            ELSE sf.ss_ext_sales_price
        END
    ) AS avg_adj_sales,
    (
        SELECT COALESCE(SUM(cs.cs_ext_sales_price), 0)
        FROM catalog_sales cs
        WHERE cs.cs_item_sk = i.i_item_sk
    ) AS catalog_sales_total,
    CASE
        WHEN inv.inv_quantity_on_hand > 1000 THEN 'HIGH_STOCK'
        WHEN inv.inv_quantity_on_hand IS NULL THEN 'NO_INVENTORY'
        ELSE 'NORMAL_STOCK'
    END AS stock_level
FROM sales_full sf
JOIN date_dim d_sold
    ON sf.ss_sold_date_sk = d_sold.d_date_sk
JOIN item i
    ON sf.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON sf.ss_promo_sk = p.p_promo_sk
JOIN customer c
    ON sf.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN inv_sample inv
    ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_date_sk = d_sold.d_date_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
    AND cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_customer_sk = c.c_customer_sk
      AND sr2.sr_return_quantity > 0
)
GROUP BY
    i.i_category,
    d_sold.d_year,
    inv.inv_quantity_on_hand,
    p.p_discount_active,
    i.i_item_sk
HAVING SUM(sf.ss_ext_sales_price) > 10000
ORDER BY net_profit DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY

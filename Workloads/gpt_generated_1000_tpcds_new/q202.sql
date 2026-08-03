WITH joined_data AS (
    SELECT
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        d.d_year,
        i.i_brand,
        i.i_item_sk,
        p.p_promo_name,
        p.p_discount_active,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        inv.inv_quantity_on_hand,
        r.r_reason_desc
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND i.i_item_sk IN (101437, 101410)
      AND wr.wr_return_quantity > 10
)
SELECT
    d_year,
    i_brand,
    SUM(cs_net_paid) AS total_sales,
    AVG(cs_net_profit) AS avg_profit,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(wr_net_loss) AS total_loss,
    MIN(wr_return_quantity) AS min_return_qty,
    MAX(inv_quantity_on_hand) AS max_inventory
FROM joined_data
GROUP BY GROUPING SETS (
    (d_year, i_brand),
    (d_year),
    (i_brand)
)
HAVING SUM(cs_net_paid) > 5000
ORDER BY total_sales DESC
LIMIT 100

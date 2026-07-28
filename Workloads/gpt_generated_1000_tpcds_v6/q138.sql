WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
),
combined_reasons AS (
    SELECT r_reason_desc FROM reason WHERE r_reason_desc LIKE 'Customer%'
    UNION
    SELECT r_reason_desc FROM reason WHERE r_reason_desc LIKE 'Vendor%'
),
sales_detail AS (
    SELECT
        cp.cp_catalog_number AS catalog_number,
        CASE
            WHEN cs.cs_net_profit > 1000 THEN 'HIGH'
            WHEN cs.cs_net_profit > 0    THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category,
        SUM(cs.cs_ext_sales_price) AS sales_sum,
        SUM(cs.cs_quantity)        AS total_quantity,
        SUM(cs.cs_net_profit)      AS profit_sum,
        i.total_qty                AS inv_qty
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inv_agg i
        ON cs.cs_item_sk = i.inv_item_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_sold.d_date_sk
    JOIN reason r
        ON r.r_reason_sk = sr.sr_reason_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_sold.d_date_sk
    WHERE cp.cp_catalog_number IN (6, 9, 12)
      AND p.p_discount_active = 'Y'
      AND d_sold.d_month_seq BETWEEN 1000 AND 1200
      AND i.total_qty > 1000
      AND cs.cs_quantity > 10
      AND d_sold.d_year <= (
          SELECT MAX(d_year) FROM date_dim WHERE d_year < 1995
      )
      AND r.r_reason_desc IN (SELECT r_reason_desc FROM combined_reasons)
    GROUP BY
        cp.cp_catalog_number,
        CASE
            WHEN cs.cs_net_profit > 1000 THEN 'HIGH'
            WHEN cs.cs_net_profit > 0    THEN 'MEDIUM'
            ELSE 'LOW'
        END,
        i.total_qty
)
SELECT
    catalog_number,
    profit_category,
    SUM(sales_sum)      AS total_sales,
    AVG(profit_sum)     AS avg_profit,
    SUM(total_quantity) AS total_units_sold
FROM sales_detail
GROUP BY catalog_number, profit_category
HAVING SUM(sales_sum) > 10000
ORDER BY total_sales DESC

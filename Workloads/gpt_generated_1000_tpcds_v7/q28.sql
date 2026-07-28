WITH joined_data AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        ss.ss_ext_sales_price AS store_sales_price,
        ws.ws_ext_sales_price AS web_sales_price,
        sr.sr_return_amt AS return_amount,
        inv.inv_quantity_on_hand AS inventory_qty
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
      AND i.i_brand = 'Brand#12'
      AND inv.inv_quantity_on_hand > 100
      AND ws.ws_ext_discount_amt > 500
      AND sr.sr_return_quantity > 0
)
SELECT
    d_date,
    d_year,
    c_customer_id,
    i_item_id,
    i_brand,
    i_category,
    SUM(store_sales_price) AS total_store_sales,
    SUM(web_sales_price) AS total_web_sales,
    SUM(return_amount) AS total_returns,
    SUM(inventory_qty) AS total_inventory_qty,
    (SUM(store_sales_price) + SUM(web_sales_price) - SUM(return_amount)) AS net_revenue,
    RANK() OVER (
        PARTITION BY d_year
        ORDER BY (SUM(store_sales_price) + SUM(web_sales_price) - SUM(return_amount)) DESC
    ) AS yearly_customer_rank
FROM joined_data
GROUP BY d_date, d_year, c_customer_id, i_item_id, i_brand, i_category
ORDER BY net_revenue DESC
LIMIT 100

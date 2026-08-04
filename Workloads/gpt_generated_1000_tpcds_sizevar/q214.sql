WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_order_number,
        cr.cr_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_addr_sk,
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_paid,
        i.i_brand,
        i.i_category,
        c.c_customer_id,
        ca.ca_state,
        cd.cd_education_status,
        ARRAY[cs.cs_sales_price, ws.ws_sales_price] AS price_array
    FROM catalog_returns cr
    FULL OUTER JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN item i
        ON COALESCE(cs.cs_item_sk, cr.cr_item_sk) = i.i_item_sk
    LEFT JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws
        ON cs.cs_order_number = ws.ws_order_number
           AND cs.cs_item_sk = ws.ws_item_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    WHERE cd.cd_education_status = 'College'
      AND i.i_brand = 'Brand#12'
      AND cs.cs_sales_price > 20
)
SELECT
    brand,
    category,
    state,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(total_return_amount)      AS total_return_amount,
    AVG(avg_price)                AS avg_of_avg_price
FROM (
    SELECT
        i_brand      AS brand,
        i_category   AS category,
        ca_state     AS state,
        c_customer_id AS customer_id,
        cr_return_amount AS total_return_amount,
        AVG(price) OVER (PARTITION BY i_brand, i_category) AS avg_price
    FROM base
    CROSS JOIN UNNEST(price_array) AS t(price)
    WHERE price > (
        SELECT MAX(cs_quantity)
        FROM catalog_sales
        WHERE cs_quantity < 5
    )
) sub
GROUP BY brand, category, state
HAVING SUM(total_return_amount) > 1000
ORDER BY total_return_amount DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY

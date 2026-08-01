WITH sr_agg AS (
    SELECT
        sr_item_sk,
        sum(sr_return_amt) AS total_return_amt,
        sum(sr_return_tax) AS total_return_tax,
        count(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_tax > 20
      AND sr_return_ship_cost > 50
    GROUP BY sr_item_sk
),
item_ws_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_units,
        i.i_item_sk,
        sum(ws.ws_ext_sales_price) AS total_sales,
        sum(ws.ws_quantity) AS total_quantity,
        sr_agg.total_return_amt,
        sr_agg.return_cnt,
        (SELECT avg(sr3.sr_return_tax)
         FROM store_returns sr3
         WHERE sr3.sr_item_sk = i.i_item_sk) AS avg_return_tax
    FROM item i
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN sr_agg
        ON sr_agg.sr_item_sk = i.i_item_sk
    WHERE i.i_units = 'Each'
      AND i.i_class_id IN (6, 14)
      AND i.i_rec_start_date >= DATE '1999-01-01'
      AND ws.ws_ext_list_price > 1000
      AND ws.ws_ship_customer_sk IN (10121251, 1492793)
      AND EXISTS (
          SELECT 1
          FROM store_returns sr_exists
          WHERE sr_exists.sr_item_sk = i.i_item_sk
            AND sr_exists.sr_return_amt > 0
      )
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_units,
        i.i_item_sk,
        sr_agg.total_return_amt,
        sr_agg.return_cnt,
        (SELECT avg(sr3.sr_return_tax)
         FROM store_returns sr3
         WHERE sr3.sr_item_sk = i.i_item_sk)
)
SELECT
    i_item_id,
    i_product_name,
    i_brand,
    i_units,
    total_sales,
    total_quantity,
    total_return_amt,
    return_cnt,
    avg_return_tax,
    rank() OVER (PARTITION BY i_brand ORDER BY total_sales DESC) AS brand_sales_rank
FROM item_ws_agg
ORDER BY brand_sales_rank, i_item_id

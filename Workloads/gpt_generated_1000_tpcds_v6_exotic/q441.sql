WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_quantity               AS cs_quantity,
        cs.cs_net_profit             AS cs_net_profit,
        cd.cd_gender,
        cd.cd_dep_count,
        i.i_category,
        i.i_brand,
        i.i_wholesale_cost,
        td.t_hour,
        td.t_am_pm,
        ws.ws_order_number,
        ws.ws_quantity               AS ws_quantity,
        ws.ws_net_profit             AS ws_net_profit,
        ws.ws_web_site_sk,
        ws.ws_ext_sales_price,
        ws.ws_sold_time_sk,
        ws.ws_item_sk
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
)
SELECT DISTINCT
    b.cs_sold_date_sk,
    b.i_category,
    b.i_brand,
    b.i_wholesale_cost,
    b.t_hour,
    ws.web_name,
    b.cs_quantity,
    b.ws_quantity,
    b.cs_net_profit,
    b.ws_net_profit,
    CASE WHEN b.ws_net_profit > b.cs_net_profit THEN 'WEB' ELSE 'CAT' END AS higher_profit_source,
    (
        SELECT AVG(cs_net_profit)
        FROM catalog_sales
        WHERE cs_item_sk = b.cs_item_sk
    ) AS avg_item_profit,
    ROW_NUMBER() OVER (
        PARTITION BY b.ws_web_site_sk
        ORDER BY (b.cs_net_profit + b.ws_net_profit) DESC
    ) AS site_profit_rank
FROM base b
JOIN web_site ws
    ON b.ws_web_site_sk = ws.web_site_sk
WHERE b.i_wholesale_cost > 5.00
  AND b.cd_dep_count <= 2
  AND b.t_hour BETWEEN 8 AND 12
  AND ws.web_zip = '84098'
  AND b.cs_quantity > 1
ORDER BY site_profit_rank, avg_item_profit DESC
LIMIT 100

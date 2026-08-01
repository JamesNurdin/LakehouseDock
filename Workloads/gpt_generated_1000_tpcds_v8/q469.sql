WITH sales_ship_full AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_carrier,
        sm.sm_code,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_ext_ship_cost
    FROM ship_mode sm
    FULL OUTER JOIN web_sales ws
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
),
return_lateral AS (
    SELECT
        ssf.sm_carrier,
        ssf.sm_code,
        ssf.ws_order_number,
        ssf.ws_quantity,
        ssf.ws_net_paid,
        wr.wr_return_amt,
        wr.wr_return_tax
    FROM sales_ship_full ssf
    CROSS JOIN LATERAL (
        SELECT wr_return_amt, wr_return_tax, wr_order_number
        FROM web_returns wr
        WHERE wr.wr_order_number = ssf.ws_order_number
          AND wr.wr_return_tax > 20.00
          AND wr.wr_return_amt > 50.00
    ) wr
    WHERE ssf.ws_order_number IS NOT NULL
),
unioned_data AS (
    SELECT
        sm_carrier,
        sm_code,
        ws_order_number,
        SUM(ws_net_paid)               AS total_sales,
        SUM(wr_return_amt)             AS total_returns
    FROM return_lateral
    WHERE ws_quantity >= 1
      AND ws_net_paid > 0
    GROUP BY CUBE (sm_carrier, sm_code, ws_order_number)

    UNION

    SELECT
        sm_carrier,
        sm_code,
        ws_order_number,
        SUM(ws_net_paid) * 0.9         AS total_sales,
        SUM(wr_return_amt) * 1.1       AS total_returns
    FROM return_lateral
    WHERE ws_quantity >= 1
      AND ws_net_paid > 0
    GROUP BY CUBE (sm_carrier, sm_code, ws_order_number)
),
intersect_orders AS (
    SELECT ws_order_number FROM web_sales
    INTERSECT
    SELECT wr_order_number FROM web_returns
),
final_query AS (
    SELECT
        ud.sm_carrier,
        ud.sm_code,
        ud.ws_order_number,
        ud.total_sales,
        ud.total_returns,
        (ud.total_sales - ud.total_returns)               AS net_margin,
        ROW_NUMBER() OVER (PARTITION BY ud.sm_carrier ORDER BY (ud.total_sales - ud.total_returns) DESC) AS rn
    FROM unioned_data ud
    WHERE ud.ws_order_number IN (SELECT ws_order_number FROM intersect_orders)
      AND ud.total_sales > 1000
      AND ud.total_returns < 500
      AND (ud.sm_carrier = 'DHL' OR ud.sm_carrier = 'FEDEX')
)
SELECT *
FROM final_query
ORDER BY net_margin DESC, rn
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
